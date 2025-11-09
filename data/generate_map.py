#!/usr/bin/env python3
# generate_map.py
import json
import folium
from folium.plugins import MarkerCluster, Fullscreen

# 讀取 locations.json
with open('locations.json', 'r', encoding='utf-8') as f:
    locations = json.load(f)

# 計算地圖中心點（所有地點的平均座標）
if locations:
    avg_lat = sum(loc['latitude'] for loc in locations) / len(locations)
    avg_lng = sum(loc['longitude'] for loc in locations) / len(locations)
else:
    avg_lat, avg_lng = 25.0330, 121.5654  # 台北市預設座標

# 建立地圖
m = folium.Map(
    location=[avg_lat, avg_lng],
    zoom_start=11,
    tiles='OpenStreetMap'
)

# 建立標記群組
marker_cluster = MarkerCluster().add_to(m)

# 添加標記點
for loc in locations:
    # 建立彈出視窗內容
    popup_html = f"<b>{loc['name']}</b>"
    if loc.get('description'):
        popup_html += f"<br>{loc['description']}"
    
    # 建立標記
    folium.Marker(
        location=[loc['latitude'], loc['longitude']],
        popup=folium.Popup(popup_html, max_width=300),
        tooltip=loc['name'],
        icon=folium.Icon(color='blue', icon='info-sign', prefix='glyphicon')
    ).add_to(marker_cluster)

# 添加全螢幕控制
Fullscreen().add_to(m)

# 儲存地圖
m.save('locations_map.html')
print(f'✅ 地圖已生成！共 {len(locations)} 個地點')

