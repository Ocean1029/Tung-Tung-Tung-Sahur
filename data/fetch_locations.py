# fetch_locations.py
import requests
import json
import time
import os
from dotenv import load_dotenv

# 載入 .env 檔案
load_dotenv()

# 從環境變數讀取 Google API Key
GOOGLE_API_KEY = os.getenv('GOOGLE_API_KEY')

if not GOOGLE_API_KEY:
    raise ValueError('請在 .env 檔案中設定 GOOGLE_API_KEY')

def fetch_nearby_places(lat, lng, radius, place_type, keyword=''):
    """從 Google Places API 取得附近地點"""
    url = 'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
    
    params = {
        'location': f'{lat},{lng}',
        'radius': radius,
        'key': GOOGLE_API_KEY,
        'language': 'zh-TW'
    }
    
    if place_type:
        params['type'] = place_type
    if keyword:
        params['keyword'] = keyword
    
    try:
        response = requests.get(url, params=params)
        data = response.json()
        
        if data['status'] not in ['OK', 'ZERO_RESULTS']:
            print(f"❌ API 錯誤: {data['status']}")
            return []
        
        return data.get('results', [])
    except Exception as e:
        print(f"❌ 請求失敗: {e}")
        return []

def get_district_coordinates(district_name):
    """透過 Geocoding API 取得行政區的經緯度"""
    url = 'https://maps.googleapis.com/maps/api/geocode/json'
    
    params = {
        'address': f'{district_name} 台北市',
        'key': GOOGLE_API_KEY,
        'language': 'zh-TW',
        'region': 'tw'
    }
    
    try:
        response = requests.get(url, params=params)
        data = response.json()
        
        if data['status'] != 'OK':
            print(f"❌ 取得 '{district_name}' 座標時發生錯誤: {data['status']}")
            return None
        
        results = data.get('results', [])
        if results:
            location = results[0]['geometry']['location']
            return {
                'lat': location['lat'],
                'lng': location['lng']
            }
        return None
    except Exception as e:
        print(f"❌ 取得 '{district_name}' 座標失敗: {e}")
        return None

def search_place_by_name(place_name, location_bias=''):
    """透過名稱搜尋特定地點（使用 Text Search API）"""
    url = 'https://maps.googleapis.com/maps/api/place/textsearch/json'
    
    # 在查詢中加入位置信息以提高準確度
    query = place_name
    if location_bias:
        # 在查詢中加入 "台北" 或 "台灣大學" 等位置關鍵字
        if '25.0173' in location_bias:  # 台大附近
            query = f"{place_name} 台灣大學"
        else:  # 台北市
            query = f"{place_name} 台北"
    
    params = {
        'query': query,
        'key': GOOGLE_API_KEY,
        'language': 'zh-TW',
        'region': 'tw'  # 限制在台灣地區
    }
    
    try:
        response = requests.get(url, params=params)
        data = response.json()
        
        if data['status'] not in ['OK', 'ZERO_RESULTS']:
            print(f"❌ 搜尋 '{place_name}' 時發生錯誤: {data['status']}")
            return None
        
        results = data.get('results', [])
        if results:
            return results[0]  # 返回第一個最相關的結果
        return None
    except Exception as e:
        print(f"❌ 搜尋 '{place_name}' 失敗: {e}")
        return None

def convert_to_location_format(place):
    """轉換成指定格式"""
    return {
        'name': place['name'],
        'latitude': place['geometry']['location']['lat'],
        'longitude': place['geometry']['location']['lng'],
        'description': place.get('vicinity', ''),
        'isNFCEnabled': False,
        'nfcId': None
    }

def remove_duplicates(locations):
    """去除重複地點"""
    seen = set()
    unique = []
    
    for loc in locations:
        key = f"{loc['name']}_{loc['latitude']:.4f}_{loc['longitude']:.4f}"
        if key not in seen:
            seen.add(key)
            unique.append(loc)
    
    return unique

def main():
    print('🎯 開始取得地點資料...\n')
    
    # 台灣大學地標（使用用戶指定的名稱）
    print('📍 正在取得台灣大學地標...')
    ntu_landmarks = [
        '國立台灣大學總圖書館',
        '台大體育館',
        '醉月湖',
        '台大椰林大道',
        '台大傅鐘'
    ]
    
    ntu_locations = []
    for landmark_name in ntu_landmarks:
        print(f"   搜尋: {landmark_name}")
        place = search_place_by_name(landmark_name, '25.0173,121.5397')
        if place:
            ntu_locations.append(convert_to_location_format(place))
            print(f"   ✅ 找到: {place['name']}")
        else:
            print(f"   ⚠️  未找到: {landmark_name}")
        time.sleep(0.5)  # 避免 API 請求過快
    
    # 台北市觀光景點（先搜尋用戶指定的景點）
    print('\n📍 正在取得台北市觀光景點...')
    
    specified_attractions = [
        '台北101',
        '國父紀念館',
        '象山步道',
        '松山文創園區',
        '國立故宮博物院',
        '中正紀念堂',
        '龍山寺',
        '西門町',
        '士林夜市',
        '饒河街夜市',
        '寧夏夜市',
        '華西街夜市',
        '臨江街夜市',
        '師大夜市',
        '公館夜市',
        '大稻埕碼頭',
        '迪化街',
        '台北賓館',
        '總統府',
        '二二八和平公園',
        '台北植物園',
        '大安森林公園',
        '陽明山國家公園',
        '擎天崗',
        '冷水坑',
        '小油坑',
        '竹子湖',
        '陽明山花季',
        '北投溫泉博物館',
        '北投圖書館',
        '地熱谷',
        '關渡宮',
        '關渡自然公園',
        '淡水老街',
        '淡水漁人碼頭',
        '紅毛城',
        '真理大學',
        '淡江中學',
        '小白宮',
        '八里左岸',
        '十三行博物館',
        '碧潭風景區',
        '木柵動物園',
        '貓空纜車',
        '貓空茶園',
        '指南宮',
        '深坑老街',
        '石碇老街',
        '平溪老街',
        '菁桐老街',
        '十分瀑布',
        '九份老街',
        '金瓜石',
        '黃金博物館',
        '象山親山步道',
        '虎山步道',
        '劍潭山步道',
        '金面山步道',
        '忠勇山步道',
        '軍艦岩步道',
        '大崙頭山步道',
        '圓山大飯店',
        '林安泰古厝',
        '美麗華摩天輪',
        '台北市立美術館',
        '花博公園',
        '台北典藏植物園',
        '新生公園',
        '榮星花園',
        '青年公園',
        '永康街',
        '東區商圈',
        '信義商圈',
        '南港展覽館',
        '台北流行音樂中心',
        '華山1914文創園區',
        '光點台北',
        '台北當代藝術館',
        '袖珍博物館',
        '郭元益糕餅博物館',
        '台北探索館',
        '北門',
        '小南門',
        '景福門',
        '台北霞海城隍廟',
        '行天宮',
        '保安宮',
        '覺修宮',
        '指南宮',
        '艋舺青山宮',
        '艋舺祖師廟',
        '文昌宮',
        '台北孔廟',
        '內湖科技園區',
        '碧湖公園',
        '大湖公園',
        '白石湖吊橋',
        '碧山巖',
        '劍南路蝴蝶步道',
        '內溝溪生態展示館'
    ]
    
    taipei_locations = []
    print("   搜尋指定的觀光景點...")
    for attraction_name in specified_attractions:
        print(f"   搜尋: {attraction_name}")
        place = search_place_by_name(attraction_name, '25.0330,121.5654')
        if place:
            taipei_locations.append(convert_to_location_format(place))
            print(f"   ✅ 找到: {place['name']}")
        else:
            print(f"   ⚠️  未找到: {attraction_name}")
        time.sleep(0.5)
    
    # 補充更多觀光景點以達到100個
    print("\n   搜尋更多台北市觀光景點...")
    
    # 台北市所有12個行政區
    taipei_districts = [
        '北投區', '士林區', '中山區', '內湖區', '大同區', 
        '松山區', '萬華區', '中正區', '大安區', '信義區', 
        '南港區', '文山區'
    ]
    
    # 動態取得各行政區的座標
    print("   正在取得各行政區座標...")
    taipei_areas = []
    for district in taipei_districts:
        print(f"   取得 {district} 座標...")
        coords = get_district_coordinates(district)
        if coords:
            taipei_areas.append({
                'name': district,
                'lat': coords['lat'],
                'lng': coords['lng'],
                'radius': 3000  # 統一使用3000公尺半徑
            })
            print(f"   ✅ {district}: ({coords['lat']:.6f}, {coords['lng']:.6f})")
        else:
            print(f"   ⚠️  無法取得 {district} 座標，跳過")
        time.sleep(0.3)  # 避免 API 請求過快
    
    # 使用關鍵字來搜尋觀光景點（補充搜尋）
    attraction_keywords = [
        '觀光景點', '博物館', '公園', '古蹟', '寺廟', 
        '夜市', '商圈', '文創園區', '步道', '紀念館'
    ]
    
    for area in taipei_areas:
        # 使用關鍵字搜尋
        for keyword in attraction_keywords:
            places = fetch_nearby_places(
                area['lat'], area['lng'],
                area['radius'], '', keyword
            )
            
            locations = [
                convert_to_location_format(p)
                for p in places
            ]
            taipei_locations.extend(locations)
            time.sleep(0.5)
    
    # 去除重複並限制數量
    ntu_final = remove_duplicates(ntu_locations)
    taipei_unique = remove_duplicates(taipei_locations)
    taipei_final = taipei_unique[:100]
    
    final_locations = ntu_final + taipei_final
    
    print(f'\n✅ 總計取得 {len(final_locations)} 個地點')
    print(f'   台大地標: {len(ntu_final)} 個')
    print(f'   台北觀光景點: {len(taipei_final)} 個')
    
    # 儲存為 JSON
    with open('locations.json', 'w', encoding='utf-8') as f:
        json.dump(final_locations, f, ensure_ascii=False, indent=2)
    
    print('\n💾 資料已儲存至 locations.json')
    
    # 預覽
    print('\n📝 台大地標預覽:')
    for i, loc in enumerate(ntu_final, 1):
        print(f"   {i}. {loc['name']}")
    
    print('\n📝 台北觀光景點前 10 筆預覽:')
    for i, loc in enumerate(taipei_final[:10], 1):
        print(f"   {i}. {loc['name']}")

if __name__ == '__main__':
    main()