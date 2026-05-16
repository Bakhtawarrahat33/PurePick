import hashlib
import json
from django.views.decorators.csrf import csrf_exempt
from django.views.decorators.http import require_http_methods
from django.http import JsonResponse
from .models import User, HealthProfile, ScanRecord, SavedProduct


def hash_password(password):
    return hashlib.sha256(password.encode()).hexdigest()


@csrf_exempt
def register_user(request):
    if request.method != 'POST':
        return JsonResponse({'error': 'POST required'}, status=405)
    try:
        data = json.loads(request.body)
        name = data.get('name', '').strip()
        username = data.get('username', '').strip()
        password = data.get('password', '').strip()

        if not all([name, username, password]):
            return JsonResponse({'error': 'name, username, and password are required'}, status=400)

        if User.objects.filter(username=username).exists():
            return JsonResponse({'error': 'Username already taken'}, status=400)

        user = User.objects.create(
            name=name,
            username=username,
            password=hash_password(password)
        )
        HealthProfile.objects.create(user=user)
        return JsonResponse({'user_id': user.id, 'name': user.name, 'username': user.username}, status=201)
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)


@csrf_exempt
def login_user(request):
    if request.method != 'POST':
        return JsonResponse({'error': 'POST required'}, status=405)
    try:
        data = json.loads(request.body)
        username = data.get('username', '').strip()
        password = data.get('password', '').strip()

        user = User.objects.filter(username=username).first()
        if not user:
            return JsonResponse({'error': 'Wrong username'}, status=401)
            
        if user.password != hash_password(password):
            return JsonResponse({'error': 'Wrong password'}, status=401)

        return JsonResponse({'user_id': user.id, 'name': user.name, 'username': user.username})
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)


@csrf_exempt
def google_login(request):
    if request.method != 'POST':
        return JsonResponse({'error': 'POST required'}, status=405)
    try:
        data = json.loads(request.body)
        token = data.get('token', '')
        # For FYP demo: decode the google token to extract email
        # In production, validate with Google API
        import base64
        try:
            padding = 4 - len(token.split('.')[1]) % 4
            payload = json.loads(base64.b64decode(token.split('.')[1] + '=' * padding))
            email = payload.get('email', f'google_user_{token[:8]}')
            name = payload.get('name', 'Google User')
        except Exception:
            email = f'google_{token[:12]}'
            name = 'Google User'

        username = email.replace('@', '_').replace('.', '_')
        user = User.objects.filter(username=username).first()
        if not user:
            user = User.objects.create(name=name, username=username, password=hash_password(token))
            HealthProfile.objects.create(user=user)

        return JsonResponse({'user_id': user.id, 'name': user.name, 'username': user.username})
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)


@csrf_exempt
def update_profile(request):
    if request.method != 'POST':
        return JsonResponse({'error': 'POST required'}, status=405)
    try:
        data = json.loads(request.body)
        user_id = data.get('user_id')
        allergies = data.get('allergies', '')

        user = User.objects.filter(id=user_id).first()
        if not user:
            return JsonResponse({'error': 'User not found'}, status=404)

        profile, _ = HealthProfile.objects.get_or_create(user=user)
        profile.allergies = data.get('allergies', profile.allergies)
        profile.skin_conditions = data.get('skin_conditions', profile.skin_conditions)
        profile.custom_allergens = data.get('custom_allergens', profile.custom_allergens)
        profile.save()
        return JsonResponse({'message': 'Profile updated successfully'})
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)


def get_profile(request, user_id):
    try:
        user = User.objects.filter(id=user_id).first()
        if not user:
            return JsonResponse({'error': 'User not found'}, status=404)
        profile, _ = HealthProfile.objects.get_or_create(user=user)
        return JsonResponse({
            'user_id': user.id,
            'name': user.name,
            'username': user.username,
            'allergies': profile.allergies,
            'skin_conditions': profile.skin_conditions,
            'custom_allergens': profile.custom_allergens,
        })
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)


def get_history(request, user_id):
    try:
        scans = ScanRecord.objects.filter(user_id=user_id).order_by('-scanned_at')[:50]
        data = [{
            'id': s.id,
            'product_name': s.product_name,
            'score': s.safety_score,
            'risk_level': s.risk_level,
            'ai_analysis': getattr(s, 'ai_analysis', ''),
            'personal_warnings': getattr(s, 'personal_warnings', ''),
            'flagged_ingredients': s.get_flagged_list(),
            'date': s.scanned_at.strftime("%Y-%m-%d %H:%M"),
        } for s in scans]
        return JsonResponse(data, safe=False)
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)


@csrf_exempt
def save_product(request):
    if request.method != 'POST':
        return JsonResponse({'error': 'POST required'}, status=405)
    try:
        data = json.loads(request.body)
        user_id = data.get('user_id')
        print(f"DEBUG: Save attempt for user {user_id} - Data: {data}")
        
        user = User.objects.filter(id=user_id).first()
        if not user:
            print(f"DEBUG: Save failed - User {user_id} not found")
            return JsonResponse({'error': f'User {user_id} not found'}, status=404)

        new_saved = SavedProduct.objects.create(
            user=user,
            name=data.get('name') or 'Unknown Product',
            brand=data.get('brand') or '',
            safety_score=int(data.get('score') or 0),
            risk_level=data.get('risk_level') or 'moderate',
            ingredients=data.get('ingredients') or '',
        )
        print(f"DEBUG: Product saved successfully with ID {new_saved.id}")
        return JsonResponse({'message': 'Product saved', 'id': new_saved.id})
    except Exception as e:
        import traceback
        print(f"DEBUG: Save Product ERROR: {str(e)}")
        print(traceback.format_exc())
        return JsonResponse({'error': str(e)}, status=500)


def get_saved(request, user_id):
    try:
        products = SavedProduct.objects.filter(user_id=user_id).order_by('-saved_at')
        data = [{
            'id': p.id,
            'name': p.name,
            'brand': p.brand,
            'safety_score': p.safety_score,
            'risk_level': p.risk_level,
            'ingredients': p.ingredients,
            'date': p.saved_at.strftime("%b %d, %Y"),
            'saved_at': p.saved_at.isoformat(),
        } for p in products]
        return JsonResponse(data, safe=False)
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)


@csrf_exempt
def delete_saved(request, product_id):
    try:
        SavedProduct.objects.filter(id=product_id).delete()
        return JsonResponse({'message': 'Deleted'})
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)
