# Ước tính calo — 27/11/2026

## Làm gọn giao diện theo phản hồi

Màn chính chỉ giữ chọn ảnh/mô tả/công thức khi chưa có bữa; khi có bữa chỉ giữ
khẩu phần và danh sách tên thực phẩm + gram. Không hiện ngày/bữa/phần đã ăn,
checkbox từng dòng, mô tả nguồn tiếng Anh hoặc mã USDA ở màn chính.
AI gợi ý nằm ngay đầu danh sách khi còn dữ liệu thiếu. Đổi loại bằng cách chạm
tên; menu ba chấm giữ đổi/bỏ nguyên liệu và xem chi tiết nguồn khi cần.

Nút dưới đổi theo bước: Ước tính calo → Tính calo → Lưu bữa ăn. Tính calo là
bước xác nhận toàn bộ danh sách, vẫn từ chối dòng thiếu loại/gram; tính xong cuộn
lên kết quả mỗi phần. Lưu bữa ăn mới mở sheet tên/ngày/bữa/phần đã ăn và tổng
kcal sẽ ghi. Sheet giữ nút lưu phía trên bàn phím ở mobile, cuộn được trên màn
ngang/chữ lớn. Picker loại thực phẩm chỉ hiện tên và kcal/100 g, chi tiết nguồn
vẫn xem được qua menu nguyên liệu, kể cả sau khi đã lưu.

Chỉ đổi presentation và kiểm thử UI, không đổi model AI, phép tính, schema hay rules.
Xác minh bản gọn: 14 test calo qua, bao gồm nhập/tính/lưu/xem nhật ký và sheet lưu
ở sáng/tối, chữ 200%, bàn phím 100 px, màn ngang 844×390. Kiểm tra nút lưu đầy đủ
nằm trên bàn phím. Analyzer 3 file UI/test không có issue; web release build đạt.
Ảnh rà: `build/ui_ux/nutrition-simple-start` và `build/ui_ux/nutrition-simple-final`.
Web đã cập nhật lúc 17:13 ngày 27/11/2026 (UTC+7), Hosting version
`b201568d70c0df72`. Đã so hash app live và Android association với build, khớp.
Log deploy: `build/nutrition/simple-ui-deploy.log`; báo cáo: `build/nutrition-simple-release.json`.
Bản localhost cần hot restart sau khi cập nhật widget/provider tree.

## Luồng người dùng

Từ 27/11: nhận diện thành công tự bổ sung tên nguyên liệu chưa có vào danh mục
dùng chung Đăng món/Tủ lạnh/Calo; xem [contract nguyên liệu](INGREDIENT_CATALOG.md).
Chỉ bổ sung tên, không tự tạo dữ liệu dinh dưỡng. Lưu DB lỗi có thể thử lại bằng
kết quả AI đã cache. Picker Calo hiện tên mới với nhãn Cần chọn dữ liệu dinh dưỡng;
dòng thiếu tham chiếu vẫn chặn tính/lưu như trước.

Bếp của tôi → Ước tính calo, hoặc Tùy chọn công thức/bữa ăn → Ước tính calo.
Người dùng có thể chụp/chọn ảnh, nhập mô tả, chọn công thức, lấy cả bữa nhiều món
hoặc thêm thực phẩm từ bảng tham chiếu. Tính thủ công từ dữ liệu đã chọn không cần
gọi AI. Nhận diện bằng AI chỉ chạy sau khi người dùng bấm nút, có thông tin ảnh/mô
tả sẽ được gửi tới dịch vụ AI. Không gửi lịch sử Chat AI, hồ sơ hoặc kho riêng.

AI gợi ý thực phẩm tham chiếu và gram. Người dùng chỉnh/chọn lại đúng sống/chín,
phần ăn được, dầu/sốt rồi bấm Tính calo để xác nhận danh sách.
Chưa đủ dữ liệu hoặc còn dòng chưa xác nhận thì không hiện tổng và không cho lưu;
không coi dòng thiếu dữ liệu là 0 calo. Có thể thêm/bỏ dòng một cách chủ động.

Kết quả hiển thị kcal/đạm/tinh bột/chất béo mỗi phần, kcal toàn bữa và phần đã ăn.
Số phần dùng chia lượng thực phẩm đang xác nhận, không tự sửa công thức/thực đơn.
Khối lượng của draft dinh dưỡng làm tròn gram nguyên để xác nhận, không sửa lượng
chính xác trong công thức/kho. Giao diện kết quả dùng số nguyên, không dãy thập phân.
Nhãn luôn là Ước tính tham khảo; không có cam kết đo chính xác từ ảnh hay chẩn đoán.

Đã ăn → Lưu nhật ký ghi đúng ngày/sáng/trưa/tối và số phần người dùng chọn. Một
draft có ID ổn định và create-if-absent; retry không nhân bản. Sau lưu khóa draft,
Ước tính bữa khác tạo ID mới. Nhật ký ăn riêng với nhật ký nấu, không tự coi đã nấu
là đã ăn. Cho xem chi tiết/xóa bản ghi riêng; không tự lưu vào hồ sơ công khai.

## Model và hạn mức dùng chung

`AiModelClient` là đường gọi provider chung của `DirectAiChatRepository` và
`DefaultNutritionRepository`; App tạo một instance theo UID. Cả hai đọc
`ai_settings/runtime` ở mỗi lượt: provider, endpoint, model, apiKey, enabled,
dailyLimit. Không tạo cấu hình calo thứ hai hoặc model/key fallback. Đổi model/bật
tắt ở admin áp dụng cho cả hai. Chat giữ prompt/lịch sử riêng; dinh dưỡng dùng
prompt JSON riêng và không ghi phản hồi nhận diện vào hội thoại.

Gemini dùng generateContent + inline_data PNG; API compatible dùng chat/completions
+ image_url data URI. Nếu model chung không nhận ảnh thì báo lỗi, vẫn có thể dùng
mô tả/thực phẩm thủ công; không đổi sang model khác ngầm. Timeout 40 s; output
giới hạn 256 KB, loại phần thought, parse JSON, không đưa key/provider body vào lỗi.
Ảnh picker giới hạn 8 MB đầu vào, decode/mã hóa PNG 960 px, tối đa 4 MB sau xử lý
để bỏ EXIF. Không upload ảnh lên Cloudinary, không lưu ảnh/base64 vào Firestore.

`ai_chat_threads/{uid}/days/{YYYY-MM-DD}` dùng chung count/activeUntil cho Chat và
nhận diện calo; mỗi lần gọi AI là một lượt, không hoàn lại quota khi provider lỗi,
giống Chat hiện hành. UTC+7, khóa 60 s. Bữa tối đa 180 dòng chia nhóm tối đa 30,
mỗi nhóm một lượt AI và retry nhóm đã xong đọc cache. Finish chỉ nhả đúng lease,
không xóa khóa của lượt mới bắt đầu sau khi lease cũ hết hạn.

Giữ kiến trúc direct API do người dùng đã chọn: active client vẫn đọc runtime key
như Chat cũ. Quota client/rules hiện hành không được gọi là hạn mức chi phí đáng tin
cậy trước client bị sửa đổi. Không đưa key vào bundle/log/tài liệu, không nâng
billing hoặc deploy Functions trong nhiệm vụ này. Không thay model/key đang chạy.

## Nguồn và phép tính

Nguồn: [USDA FoodData Central SR Legacy](https://fdc.nal.usda.gov/download-datasets/),
archive CSV April 2018, hash và cách import ở [README dữ liệu](../assets/nutrition/README.md).
7.793 thực phẩm đủ bốn nutrient; 64 nhãn Việt thường dùng, giữ nguyên FDC ID và
description nguồn. Tìm thực phẩm theo tên Việt/tên Anh hoặc mã USDA, đối chiếu
đúng trạng thái sống/chín. Bản ghi thiếu nutrient bị loại khỏi asset, không điền 0.

AI chỉ được chọn trong danh sách gợi ý 64 tham chiếu; ID lạ về null để người dùng
chọn thủ công trong toàn bảng. Không dùng bất kỳ kcal/macros nào model tự trả.
Khối lượng AI âm/không hữu hạn/quá 100.000 g bị từ chối. Input công thức phải được
trả đủ ID, không lặp/bỏ/gộp; gram có sẵn được giữ, ml/cái/quả không tự coi là gram.
Đổi sang gram từ đơn vị đó chỉ là gợi ý AI, vẫn cần người dùng xác nhận.

App tính tổng nutrient = tổng(per100g × grams / 100); mỗi phần = tổng / số phần;
nhật ký = mỗi phần × phần đã ăn. Không áp quy tắc 4/9 thay energy nguồn.
Việc chọn sai loại thực phẩm hoặc ước lượng gram sai vẫn làm kết quả sai; cần kiểm
tra khối lượng và cách chế biến thực tế, không gắn nhãn kết quả là số đo y khoa.

## Lưu trữ, quyền và vòng đời

- `users/{uid}/nutrition_logs/{id}`: title/day/slot/bodyJson + schemaVersion=1,
  updatedAt server; body chứa dòng đã xác nhận, gram, FDC ID, bản tham chiếu, phần
  toàn bữa/đã ăn và tổng đã ăn. Tối đa 180 dòng/100 KB; owner active đọc/tạo/xóa,
  không update. Codec ứng dụng kiểm từng dòng; rules giới hạn string, không parse
  bodyJson. Payload này không dùng ghi nguồn dinh dưỡng hoặc dữ liệu công khai.
- `ai_nutrition_threads/{uid}/requests/{id}`: digest SHA-256 input, lease/attempts,
  status processing/done/failed và resultJson <=60 KB; không lưu input/ảnh/key.
  UID owner active; digest không đổi, done không bị ghi lại. Kết quả AI vẫn là gợi
  ý chưa xác nhận, không phải bản ghi đã ăn.
- Audit dùng `ai_chat_events` hiện có; dữ liệu/permission quản trị không mở rộng.
  Không cần index mới. Lịch sử đọc tối đa 500 mục cập nhật gần nhất và có cảnh báo.
- App/Repository/Cubit được tạo lại khi UID đổi; kiểm phiên trước/sau network và
  transaction, không áp phản hồi của tài khoản cũ lên phiên mới.

## Xác minh

- Test dinh dưỡng/model chung: cả Gemini và compatible, đổi cấu hình, ảnh wire
  format, không dùng nutrient AI bịa, account switching, gram thiếu, lưu một lần,
  recipe seed, UI sáng/tối + chữ 200% + bàn phím, điện thoại ngang/dọc/tablet.
- SDK demo: lease Chat/Calo chặn nhau, shared daily count, cache retry, nhật ký
  create-if-absent và từ chối overwrite. Rules REST: cross-account, locked account,
  payload quá giới hạn, job digest/done bất biến. Không ghi bữa thử production.
- Live provider: đã nhận diện một ảnh salad công khai có sẵn trong app, dùng đúng
  Gemini `gemini-3.5-flash-lite` từ runtime hiện hành; không đổi config, không gửi
  ảnh người dùng. Báo cáo không có key: `build/nutrition/provider-smoke.json`.
- `tool/nutrition_provider_smoke.cjs --live` gọi đúng một lượt provider; mặc định
  không chạy khi thiếu cờ. Không log cấu hình runtime/response body.

Kết quả local:

- Toàn suite: 439 passed, 4 skipped (`build/nutrition/full-tests.log`), trước lần
  làm gọn phần đầu của màn đã chọn bữa và bổ sung test nhập/lưu bằng widget.
- Sau chỉnh giao diện cuối: 19 test dinh dưỡng + Chat direct đều qua, gồm tải asset
  qua repository thật và nhập tên không mất focus rồi lưu/xem nhật ký trên widget.
- Analyzer toàn app không có error, chỉ còn 4 issue cũ ở HTTP AI cũ/login/messages;
  không thêm issue mới.
- Emulator: 57 auth/Firestore + 28 engagement + 31 bữa + 22 nutrition checks đều qua;
  Flutter Firebase SDK thật trên Chrome headless riêng qua cả shared quota/cache/
  nhật ký immutable. Log: `build/nutrition/emulator.log`.
- Đã rà ảnh cuối ở `build/ui_ux/nutrition-final` tại 390×844, 800×1100, 1024×768.
  UI test bao gồm theme tối, điện thoại 844×390, chữ 200% và inset bàn phím.
- Đã gọi model thật một lượt bằng ảnh mẫu công khai, không chỉ dùng phản hồi giả.
  Chưa kiểm camera trên điện thoại vật lý hoặc phát hành APK/IPA.

## Phát hành đã xác minh

Web và rules đã deploy ngày 27/11/2026 lúc 16:50 (UTC+7), project `bepxinh-b0be7`.

- Hosting version: `b080ab3ede2ac559`, https://bepxinh-b0be7.web.app.
- Ruleset: `a4baee78-8947-4caa-8edf-9da1472d323d`, updateTime
  `2026-11-27T09:50:23.619969Z`.
- Rules SHA-256 chuẩn hóa LF:
  `5a8ec245f50d91d1cd6bbc77c70bb92c31c14d6f3972e94cb50b944e705473f8`.
- Đã đọc lại Rules API và so source chính xác; index.html, main.dart.js,
  `.well-known/assetlinks.json` và asset USDA công khai có hash khớp build local.
  Android association giữ HTTP 200/JSON. Báo cáo: `build/nutrition/release.json`.
- Chỉ deploy Firestore rules và Hosting app. Không deploy admin/Functions/index,
  không đổi runtime AI/model/key, không ghi nhật ký thử của người dùng production.
- Bản localhost cần hot restart để nạp các provider/route mới. APK/IPA chưa phát hành.

Kiểm tra lại bằng `npm.cmd exec --yes --package=firebase-tools@15.34.2 -- node tool/verify_meal_release.cjs --nutrition`.
