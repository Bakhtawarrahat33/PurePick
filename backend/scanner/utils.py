import pickle
import os
import uuid
from datetime import datetime
from django.conf import settings

def save_scan_pkl(original_scan_data: dict, user_id: str) -> str:
    """
    Saves original (non-predicted) scan data to a .pkl file.
    Follows PurePick Stage 6 Pipeline rules.
    """
    try:
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        filename = f"scan_{user_id}_{timestamp}_{uuid.uuid4().hex[:6]}.pkl"
        
        # Ensure the scans directory exists
        scans_dir = os.path.join(settings.BASE_DIR, 'scans')
        os.makedirs(scans_dir, exist_ok=True)
        
        filepath = os.path.join(scans_dir, filename)
        
        with open(filepath, "wb") as f:
            pickle.dump(original_scan_data, f)
            
        return f"scans/{filename}"
    except Exception as e:
        print(f"[PKL SAVE ERROR] {e}")
        return None
