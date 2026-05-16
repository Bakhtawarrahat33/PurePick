from django.urls import path
from . import views
from purepick_core import views as core_views

urlpatterns = [
    # Auth
    path('register/', core_views.register_user),
    path('login/', core_views.login_user),
    path('google-login/', core_views.google_login),

    # Profile
    path('profile/update/', core_views.update_profile),
    path('profile/<int:user_id>/', core_views.get_profile),

    # AI Analysis
    path('analyze/', views.analyze_ingredients),
    path('scan-label/', views.scan_label_image),
    path('alternatives/', views.get_alternatives),

    # History
    path('history/<int:user_id>/', core_views.get_history),

    # Saved products
    path('saved/add/', core_views.save_product),
    path('saved/<int:user_id>/', core_views.get_saved),
    path('saved/delete/<int:product_id>/', core_views.delete_saved),

    # AI Chat & Tips
    path('chat/', views.chat_with_ai),
    path('ai-tips/<int:user_id>/', views.get_ai_tips),
    path('home-stats/<int:user_id>/', views.get_home_stats),
]
