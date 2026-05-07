import requests
import json
from django.conf import settings

def send_fast2sms_otp(phone, otp):
    """
    Utility function to send OTP via Fast2SMS API using Quick SMS route.
    """
    # Always print OTP to terminal for development/debugging
    print(f"\n[OTP MOCK/DEBUG] Your Lifeline verification code is {otp} (for {phone})\n")

    api_key = getattr(settings, 'FAST2SMS_API_KEY', None)
    
    if not api_key:
        print(f"[WARNING] FAST2SMS_API_KEY not found in settings. API call skipped.")
        return False

    url = "https://www.fast2sms.com/dev/bulkV2"
    
    # Fast2SMS expects numbers without '+' for Indian numbers usually.
    clean_phone = phone.replace('+', '')

    # Quick SMS parameters
    payload = {
        "message": f"Your Lifeline verification code is {otp}",
        "route": "q",
        "numbers": clean_phone,
    }
    
    headers = {
        'authorization': api_key,
        'Content-Type': "application/json"
    }

    try:
        response = requests.post(url, data=json.dumps(payload), headers=headers)
        
        if response.status_code == 200:
            response_data = response.json()
            print(f"[FAST2SMS] Success: {response_data}")
            return response_data.get('return', False)
        else:
            print(f"[FAST2SMS] Error: Received status code {response.status_code}")
            print(f"[FAST2SMS] Response body: {response.text}")
            return False
    except Exception as e:
        print(f"[FAST2SMS] Exception occurred: {e}")
        return False
