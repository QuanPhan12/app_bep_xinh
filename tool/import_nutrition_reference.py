"""Trích dữ liệu USDA SR Legacy; không tự điền giá trị thiếu hoặc dùng số AI tạo."""
import argparse, csv, hashlib, io, json, zipfile
from pathlib import Path

URL='https://fdc.nal.usda.gov/fdc-datasets/FoodData_Central_sr_legacy_food_csv_2018-04.zip'
# Mã NDB là mã nguồn, không phải giá trị dinh dưỡng tự nhập.
COMMON={
 'egg':(1123,'Trứng gà sống'), 'egg_fried':(1128,'Trứng gà chiên'),
 'egg_boiled':(1129,'Trứng gà luộc chín'), 'egg_scrambled':(1132,'Trứng gà bác'),
 'milk':(1077,'Sữa bò nguyên kem'),
 'butter':(1001,'Bơ mặn'), 'salt':(2047,'Muối ăn'), 'olive_oil':(4053,'Dầu ô liu'),
 'cooking_oil':(4044,'Dầu đậu nành'), 'chicken':(5062,'Ức gà sống, bỏ da'), 'chicken_cooked':(5064,'Ức gà đã nướng'),
 'beef':(23562,'Thịt bò xay sống, 90% nạc'), 'beef_cooked':(23565,'Thịt bò xay đã áp chảo'),
 'pork':(10020,'Thịt thăn heo sống, có mỡ'), 'pork_cooked':(10023,'Thịt thăn heo đã nướng'),
 'tofu':(16427,'Đậu hũ thường, chưa nấu'), 'tofu_firm':(16426,'Đậu hũ chắc, chưa nấu'), 'tofu_fried':(16129,'Đậu hũ chiên'),
 'salmon':(15236,'Cá hồi nuôi sống'), 'shrimp':(15149,'Tôm sống'),
 'rice':(20044,'Gạo trắng, chưa nấu'), 'cooked_rice':(20045,'Cơm trắng đã nấu'),
 'rice_noodles':(20133,'Bún hoặc phở gạo khô'), 'bread':(18069,'Bánh mì trắng'),
 'flour':(20081,'Bột mì trắng'), 'rice_flour':(20061,'Bột gạo trắng'),
 'sugar':(19335,'Đường cát'), 'fish_sauce':(6179,'Nước mắm'),
 'coconut_milk':(12118,'Nước cốt dừa đóng hộp'), 'peanut':(16087,'Đậu phộng sống'),
 'tomato':(11529,'Cà chua sống'), 'carrot':(11124,'Cà rốt sống'),
 'potato':(11352,'Khoai tây sống, cả vỏ'), 'sweet_potato':(11507,'Khoai lang sống'),
 'cucumber':(11205,'Dưa leo sống, cả vỏ'), 'onion':(11282,'Hành tây sống'),
 'garlic':(11215,'Tỏi sống'), 'broccoli':(11090,'Bông cải xanh sống'),
 'cabbage':(11109,'Bắp cải sống'), 'spinach':(11457,'Rau bina sống'),
 'kale':(11233,'Cải xoăn sống'), 'mustard_greens':(11270,'Cải bẹ xanh sống'),
 'green_beans':(11052,'Đậu que sống'), 'mushroom':(11260,'Nấm trắng sống'),
 'coriander':(11165,'Ngò rí sống'), 'apple':(9003,'Táo sống, cả vỏ'),
 'banana':(9040,'Chuối'), 'orange':(9200,'Cam'), 'blueberries':(9050,'Việt quất'),
 'pork_belly':(10005,'Thịt ba chỉ heo sống'), 'rice_noodles_cooked':(20134,'Bún hoặc phở gạo đã nấu'),
 'ginger':(11216,'Gừng sống'), 'lettuce':(11253,'Xà lách lá xanh sống'),
 'romaine':(11251,'Xà lách romaine sống'), 'corn':(11167,'Bắp ngọt sống'),
 'red_bell_pepper':(11821,'Ớt chuông đỏ sống'), 'green_bell_pepper':(11333,'Ớt chuông xanh sống'),
 'sesame':(12023,'Hạt mè khô'), 'avocado':(9037,'Quả bơ sống'),
 'squid':(15175,'Mực sống'), 'soy_sauce':(16123,'Nước tương từ đậu nành và lúa mì'),
 'tilapia':(15261,'Cá rô phi sống'), 'lime_juice':(9160,'Nước chanh xanh'), 'lemon_juice':(9152,'Nước chanh vàng'),
}
def main():
 p=argparse.ArgumentParser();p.add_argument('archive');p.add_argument('--output',default='assets/nutrition/usda_sr_legacy.json');args=p.parse_args()
 archive=Path(args.archive);z=zipfile.ZipFile(archive);prefix=z.namelist()[0]
 def rows(name):return csv.DictReader(io.TextIOWrapper(z.open(prefix+name),encoding='utf-8-sig'))
 foods={r['fdc_id']:r for r in rows('food.csv')}
 codes={int(r['NDB_number']):r['fdc_id'] for r in rows('sr_legacy_food.csv')}
 common={codes[code]:(key,name) for key,(code,name) in COMMON.items()}
 nutrients={}
 keys={'1008':'kcal','1003':'protein','1004':'fat','1005':'carbs'}
 for row in rows('food_nutrient.csv'):
  if row['nutrient_id'] in keys and row['amount']!='':nutrients.setdefault(row['fdc_id'],{})[keys[row['nutrient_id']]]=float(row['amount'])
 result=[]
 for fid,food in foods.items():
  values=nutrients.get(fid,{})
  if set(values)!=set(keys.values()):continue
  assert all(v>=0 and v<float('inf') for v in values.values())
  item={'id':fid,'name':common[fid][1] if fid in common else food['description'],
    'description':food['description'],**values}
  if fid in common:item['ingredientId']=common[fid][0]
  result.append(item)
 assert len(result)>7000
 missing=set(common)-{r['id'] for r in result};assert not missing,missing
 data={'version':'USDA-SR-Legacy-2018-04','source':'https://fdc.nal.usda.gov/download-datasets/',
   'download':URL,'archiveSha256':hashlib.sha256(archive.read_bytes()).hexdigest(),
   'basis':'Nutrients per 100 g edible portion; USDA SR Legacy; missing records excluded',
   'foods':sorted(result,key=lambda r:(r.get('ingredientId') is None,r['name']))}
 output=Path(args.output);output.parent.mkdir(parents=True,exist_ok=True)
 output.write_text(json.dumps(data,ensure_ascii=False,separators=(',',':')),encoding='utf-8')
 print(json.dumps({'records':len(result),'common':len(common),'bytes':output.stat().st_size,'archiveSha256':data['archiveSha256']}))
if __name__=='__main__':main()
