"""
Scanner Views — All 14 API Endpoints
Handles: analyze, scan-label (OCR), chat, ai-tips, alternatives
Plus delegates auth/profile/history/saved to purepick_core
"""
import json
import os
import tempfile
import logging
from datetime import datetime
from django.views.decorators.csrf import csrf_exempt
from django.http import JsonResponse
from django.conf import settings

from .ingredient_analyzer import get_analyzer
from .ocr_engine import extract_text_from_image, parse_ingredients_from_text
from purepick_core.views import (
    register_user, login_user, google_login,
    update_profile, get_profile,
    get_history, save_product, get_saved, delete_saved
)
from purepick_core.models import User, HealthProfile, ScanRecord

logger = logging.getLogger(__name__)


# ------------------------------------------------------
# AI ANALYSIS ENDPOINTS
# ------------------------------------------------------

@csrf_exempt
def analyze_ingredients(request):
    """
    POST /api/analyze/
    Body: {"ingredients": ["water", "sodium lauryl sulfate", ...], "user_id": 1}
    Returns: full safety report with per-ingredient breakdown and overall score
    """
    if request.method != 'POST':
        return JsonResponse({'error': 'POST required'}, status=405)
    try:
        data = json.loads(request.body)
        ingredients = data.get('ingredients', [])
        user_id = data.get('user_id')

        if not ingredients:
            return JsonResponse({'error': 'ingredients list is required'}, status=400)

        # Get user allergies for personalization
        user_allergies = []
        if user_id:
            try:
                profile = HealthProfile.objects.get(user_id=user_id)
                user_allergies = profile.get_allergies_list()
            except HealthProfile.DoesNotExist:
                pass

        # Run the AI analysis pipeline
        analyzer = get_analyzer()
        report = analyzer.analyze(ingredients, user_allergies=user_allergies)

        # Save to scan history
        if user_id:
            try:
                ScanRecord.objects.create(
                    user_id=user_id,
                    product_name='Analyzed Product',
                    ingredients_raw=', '.join(ingredients),
                    safety_score=report['overall_score'],
                    risk_level=report['risk_level'],
                    flagged_ingredients=json.dumps(report['flagged_ingredients']),
                )
            except Exception as e:
                logger.warning("Could not save scan record: %s", e)

        return JsonResponse(report)

    except Exception as e:
        logger.error("analyze_ingredients error: %s", e)
        return JsonResponse({'error': str(e)}, status=500)


@csrf_exempt
def scan_label_image(request):
    """
    POST /api/scan-label/
    Multipart form: image file + user_id field
    Full pipeline: Image ? OCR ? Parse ? Analyze ? Report
    """
    if request.method != 'POST':
        return JsonResponse({'error': 'POST required'}, status=405)
    try:
        user_id = request.POST.get('user_id')
        image_file = request.FILES.get('image')

        if not image_file:
            return JsonResponse({'error': 'image file is required'}, status=400)

        # Save uploaded image temporarily
        suffix = os.path.splitext(image_file.name)[1] or '.jpg'
        with tempfile.NamedTemporaryFile(delete=False, suffix=suffix) as tmp:
            for chunk in image_file.chunks():
                tmp.write(chunk)
            tmp_path = tmp.name

        try:
            # Stage 1: OCR
            raw_text = extract_text_from_image(tmp_path)

            # Stage 2: Parse ingredients from text
            ingredients = parse_ingredients_from_text(raw_text)

            if not ingredients:
                return JsonResponse({
                    'error': 'Could not extract ingredients from image. Please ensure the label is clear and well-lit.',
                    'raw_text': raw_text[:200]
                }, status=422)

            # Stage 3: Get user allergies
            user_allergies = []
            if user_id:
                try:
                    profile = HealthProfile.objects.get(user_id=int(user_id))
                    user_allergies = profile.get_allergies_list()
                except Exception:
                    pass

            # Stage 0: Load User Profile FRESH from DB
            user_profile = {
                "allergies": [],
                "skin_conditions": [],
                "dietary_restrictions": [],
                "profile_missing": True
            }
            if user_id:
                try:
                    from purepick_core.models import HealthProfile
                    profile_obj = HealthProfile.objects.get(user_id=user_id)
                    user_profile = {
                        "allergies": profile_obj.get_allergies_list(),
                        "skin_conditions": [s.strip().lower() for s in profile_obj.skin_conditions.split(',') if s.strip()],
                        "custom_allergens": [c.strip().lower() for c in profile_obj.custom_allergens.split(',') if c.strip()],
                        "dietary_restrictions": [], # Placeholder for future field
                        "profile_missing": False,
                        "last_updated": str(profile_obj.updated_at)
                    }
                except HealthProfile.DoesNotExist:
                    pass

            # Stage 4-6: Analyze with Fresh Profile
            analyzer = get_analyzer()
            report = analyzer.analyze(ingredients, user_profile=user_profile)
            report['user_profile_used'] = user_profile
            report['extracted_ingredients'] = ingredients
            report['raw_text_preview'] = raw_text[:300]

            # Stage 6: Save raw scan data to .pkl
            from .utils import save_scan_pkl
            original_scan_data = {
                "user_id": user_id,
                "timestamp": str(datetime.now()),
                "ocr_raw_text": raw_text,
                "ingredient_tokens_raw": ingredients,
            }
            pkl_path = save_scan_pkl(original_scan_data, user_id or "guest")
            report['pkl_path'] = pkl_path

            # Save to history
            if user_id:
                try:
                    from purepick_core.models import ScanRecord
                    # Map new report structure to DB fields
                    risk_band = report.get('risk', {}).get('risk_band', 'Moderate').lower()
                    # Guess product name from first line of OCR text if not in report
                    guessed_name = raw_text.split('\n')[0].strip()[:50] if raw_text else "Scanned Product"
                    ScanRecord.objects.create(
                        user_id=user_id,
                        product_name=report.get('product_name') or guessed_name,
                        ingredients_raw=", ".join(ingredients),
                        safety_score=report.get('overall_score', 50),
                        risk_level=risk_band if risk_band in ['safe', 'moderate', 'high'] else 'moderate',
                        flagged_ingredients=json.dumps([a['ingredient'] for a in report.get('allergy_result', {}).get('allergy_alerts', [])]),
                        ai_analysis=report.get('ai_insight', ''),
                        personal_warnings=report.get('personal_warnings', '')
                    )

                except Exception as e:
                    print(f"Could not save scan record: {e}")

            return JsonResponse(report)

        finally:
            os.unlink(tmp_path)

    except Exception as e:
        logger.error("scan_label_image error: %s", e)
        return JsonResponse({'error': str(e)}, status=500)


@csrf_exempt
def get_alternatives(request):
    """
    POST /api/alternatives/
    Body: {"danger_ingredients": ["sodium lauryl sulfate", "fragrance"]}
    Returns safer alternatives for each flagged ingredient.
    """
    if request.method != 'POST':
        return JsonResponse({'error': 'POST required'}, status=405)
    try:
        data = json.loads(request.body)
        danger_list = data.get('danger_ingredients', [])

        ALTERNATIVES = {
            'sodium lauryl sulfate': 'Sodium Cocoyl Isethionate (gentle surfactant)',
            'sls': 'Sodium Cocoyl Isethionate or Coco Glucoside',
            'fragrance': 'Essential oils (lavender, chamomile) or fragrance-free products',
            'parfum': 'Natural essential oil blends',
            'parabens': 'Phenoxyethanol or rosemary extract as preservative',
            'mineral oil': 'Jojoba oil, squalane, or rosehip oil',
            'petrolatum': 'Shea butter or cocoa butter',
            'oxybenzone': 'Zinc oxide or titanium dioxide (mineral sunscreen)',
            'octinoxate': 'Zinc oxide mineral filter',
            'formaldehyde': 'Vitamin E or sodium benzoate (safer preservatives)',
            'triclosan': 'Tea tree oil or thymol',
            'propylene glycol': 'Glycerin or hyaluronic acid',
            'alcohol denat': 'Witch hazel or niacinamide toner',
            'synthetic dyes': 'Iron oxides or plant-based colorants',
            'hydroquinone': 'Kojic acid, vitamin C, or niacinamide for brightening',
        }

        alternatives = []
        for ing in danger_list:
            norm = ing.lower().strip()
            alt = None
            for key, val in ALTERNATIVES.items():
                if key in norm or norm in key:
                    alt = val
                    break
            alternatives.append({
                'ingredient': ing,
                'safer_alternative': alt or 'Look for products without this ingredient',
            })

        return JsonResponse({'alternatives': alternatives})

    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)


# ------------------------------------------------------
# AI CHAT & TIPS (Gemini-powered)
# ------------------------------------------------------

def _call_gemini(prompt: str, fallback: str) -> str:
    """Call Gemini API with a prompt. Returns fallback on failure."""
    api_key = getattr(settings, 'GEMINI_API_KEY', None)
    if not api_key:
        logger.error("GEMINI_API_KEY is missing!")
        return fallback
    try:
        import google.generativeai as genai
        genai.configure(api_key=api_key)
        
        # Using the newest model available on your list
        for model_name in ['gemini-2.0-flash', 'gemini-2.5-flash', 'gemini-pro-latest']:
            try:
                model = genai.GenerativeModel(model_name)
                response = model.generate_content(prompt)
                if response and response.text:
                    print(f"DEBUG: Gemini Success with {model_name}!")
                    return response.text
            except Exception as e_inner:
                print(f"DEBUG: Model {model_name} failed: {str(e_inner)}")
                continue
        
        return fallback
    except Exception as e:
        print(f"DEBUG: Gemini General Error: {str(e)}")
        return fallback


@csrf_exempt
def chat_with_ai(request):
    """
    POST /api/chat/
    Body: {"query": "...", "user_id": 1}
    """
    if request.method != 'POST':
        return JsonResponse({'error': 'POST required'}, status=405)
    try:
        data = json.loads(request.body)
        query = data.get('query', '').strip()
        user_id = data.get('user_id')

        if not query:
            return JsonResponse({'error': 'query is required'}, status=400)

        # 1. Build System Context (Blueprint Stage 1)
        profile_str = "No profile set."
        history_str = "No scans yet."
        
        if user_id:
            try:
                profile = HealthProfile.objects.get(user_id=user_id)
                profile_str = f"Allergies: {profile.allergies}. Skin: {profile.skin_conditions}. Custom: {profile.custom_allergens}"
                
                scans = ScanRecord.objects.filter(user_id=user_id).order_by('-scanned_at')[:5]
                if scans:
                    history_str = "Recent Scans:\n" + "\n".join([f"- {s.product_name}: {s.risk_level}" for s in scans])
            except: pass

        prompt = f"""
You are PurePick AI — a knowledgeable product safety assistant.
USER CONTEXT:
{profile_str}

{history_str}

RULES:
1. Use the context above to give PERSONALIZED safety advice.
2. If they ask about an ingredient, check if it triggers their allergies.
3. Be concise and helpful. Never say you are a demo.

User question: {query}
"""
        fallback = "I'm having trouble connecting to my knowledge base. Please try again."
        response_text = _call_gemini(prompt, fallback)
        return JsonResponse({'response': response_text})

    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)


def get_ai_tips(request, user_id):
    """
    GET /api/ai-tips/<user_id>/
    Returns personalized health tips based on the user's scan history and profile.
    """
    try:
        user = User.objects.filter(id=user_id).first()
        if not user:
            return JsonResponse({'error': 'User not found'}, status=404)

        # Gather context from scan history
        recent_scans = ScanRecord.objects.filter(user_id=user_id).order_by('-scanned_at')[:5]
        flagged_items = []
        for scan in recent_scans:
            flagged_items.extend(scan.get_flagged_list())

        try:
            profile = HealthProfile.objects.get(user_id=user_id)
            allergies = profile.allergies
        except HealthProfile.DoesNotExist:
            allergies = ""

        # Build Gemini prompt (Stage 1 & 2 of blueprint)
        allergies_str = allergies or "none"
        scan_context = "No scans yet."
        if recent_scans:
            scan_context = "\n".join([f"- {s.product_name}: {s.risk_level} risk" for s in recent_scans])

        prompt = f"""
You are PurePick's AI skincare advisor. Generate exactly 5 personalized skincare safety tips for this specific user.

USER HEALTH PROFILE:
- Allergies: {allergies_str}

RECENT SCAN HISTORY:
{scan_context}

FORMAT: Return ONLY a JSON array of objects:
[
  {{
    "title": "Short title",
    "body": "2-3 sentences explaining why it matters for THEIR profile",
    "category": "Allergy|Skin Condition|Ingredient Watch|General Safety",
    "severity": "High|Medium|Low",
    "related_ingredient": "name or null"
  }}
]
"""
        fallback_tips = [
            {"title": "Check for SLS", "body": "Sodium Lauryl Sulfate is a common irritant found in many cleansers.", "category": "Ingredient Watch", "severity": "Medium", "related_ingredient": "SLS"},
            {"title": "Fragrance Sensitivity", "body": "Synthetic fragrances can trigger hidden allergies even in low amounts.", "category": "Allergy", "severity": "High", "related_ingredient": "Parfum"}
        ]

        raw_response = _call_gemini(prompt, "")
        tips = fallback_tips
        if raw_response:
            try:
                import re
                json_match = re.search(r'\[.*?\]', raw_response, re.DOTALL)
                if json_match:
                    tips = json.loads(json_match.group())
            except Exception:
                pass

        return JsonResponse({'tips': tips})
    except Exception as e:
        logger.error("get_ai_tips error: %s", e)
        return JsonResponse({'error': str(e)}, status=500)

@csrf_exempt
def get_home_stats(request, user_id):
    """
    GET /api/home-stats/<user_id>/
    Returns real stats for the home screen (blueprint feature 5).
    """
    try:
        from django.db.models import Avg
        from purepick_core.models import ScanRecord
        
        total_scans = ScanRecord.objects.filter(user_id=user_id).count()
        
        # Calculate average safety score
        avg_safety_data = ScanRecord.objects.filter(user_id=user_id).aggregate(Avg('safety_score'))
        avg_safety = avg_safety_data['safety_score__avg'] or 0
        
        # Get last 3 scans
        recent = ScanRecord.objects.filter(user_id=user_id).order_by('-scanned_at')[:3]
        recent_list = [{
            "name": s.product_name,
            "band": s.risk_level,
            "score": s.safety_score,
            "date": s.scanned_at.strftime("%b %d, %H:%M")
        } for s in recent]

        print(f"DEBUG: Home Stats for {user_id}: Scans={total_scans}, Avg={avg_safety}")

        return JsonResponse({
            "total_scans": total_scans,
            "avg_safety": f"{int(avg_safety)}%",
            "recent_scans": recent_list
        })
    except Exception as e:
        import traceback
        print(f"DEBUG: Home Stats ERROR: {str(e)}")
        print(traceback.format_exc())
        return JsonResponse({'error': str(e)}, status=500)
