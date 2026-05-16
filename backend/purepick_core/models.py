from django.db import models
import json


class User(models.Model):
    name = models.CharField(max_length=200)
    username = models.CharField(max_length=100, unique=True)
    password = models.CharField(max_length=255)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.username


class HealthProfile(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='profile')
    allergies = models.TextField(blank=True, default='')
    skin_conditions = models.TextField(blank=True, default='')
    custom_allergens = models.TextField(blank=True, default='') # New: For free-text avoidance
    updated_at = models.DateTimeField(auto_now=True)

    def get_allergies_list(self):
        if not self.allergies:
            return []
        return [a.strip().lower() for a in self.allergies.split(',') if a.strip()]

    def __str__(self):
        return f"Profile of {self.user.username}"


class ScanRecord(models.Model):
    RISK_CHOICES = [
        ('safe', 'Safe'),
        ('moderate', 'Moderate'),
        ('high', 'High Risk'),
    ]
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='scans')
    product_name = models.CharField(max_length=300, blank=True, default='Scanned Product')
    ingredients_raw = models.TextField(blank=True, default='')
    safety_score = models.IntegerField(default=0)
    risk_level = models.CharField(max_length=20, choices=RISK_CHOICES, default='moderate')
    flagged_ingredients = models.TextField(blank=True, default='[]')
    ai_analysis = models.TextField(blank=True, default='')
    personal_warnings = models.TextField(blank=True, default='')
    scanned_at = models.DateTimeField(auto_now_add=True)

    def get_flagged_list(self):
        try:
            return json.loads(self.flagged_ingredients)
        except Exception:
            return []

    def __str__(self):
        return f"{self.user.username} | Score:{self.safety_score} | {self.scanned_at.date()}"


class SavedProduct(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='saved_products')
    name = models.CharField(max_length=300)
    brand = models.CharField(max_length=200, blank=True, default='')
    safety_score = models.IntegerField(default=0)
    risk_level = models.CharField(max_length=20, blank=True, default='moderate')
    ingredients = models.TextField(blank=True, default='')
    saved_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.name} (saved by {self.user.username})"
