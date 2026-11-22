# Kế hoạch bổ sung 10 chức năng cho Bếp Xinh

Trạng thái cập nhật 16/11/2026: đã triển khai MVP mục 2–10 trong source theo yêu cầu.
Mục 1 (giỏ đi chợ thật) bị loại khỏi phạm vi. Thực đơn chỉ tổng hợp/sao chép nguyên liệu,
không chuyển sang giỏ. Xem [bản bàn giao](KITCHEN_FEATURES.md) để biết contract thực tế,
kiểm thử, giới hạn và các bước phát hành. Firestore rules/index đã deploy trong
[đợt phát hành riêng](FIRESTORE_DEPLOYMENT.md); app web đã phát hành trong
[đợt bổ sung quản lý bài](RECIPE_VISIBILITY.md).
Phần đề xuất gốc dưới đây là cơ sở thiết kế; bản bàn giao là mô tả implementation hiện tại.
Độ lớn S/M/L là tương đối, không phải cam kết thời gian.

## Cơ sở hiện tại

Đã kiểm tra source: app có tìm kiếm và bộ lọc, công thức đã lưu, chọn nguyên liệu
trong Tủ lạnh, điều chỉnh khẩu phần, chế độ nấu theo bước, hồ sơ công khai,
nhắn tin, thông báo duyệt bài và luồng đăng/duyệt công thức.

Giỏ đi chợ hiện là danh sách mẫu. Tồn kho lưu ID nguyên liệu, chưa có số lượng
hay hạn dùng. Hoàn tất nấu hiện cập nhật state của màn, chưa ghi nhật ký lâu dài.
Điểm đánh giá được hiển thị từ dữ liệu món, chưa có luồng người dùng gửi đánh giá.
Vì vậy các đề xuất dưới đây mở rộng năng lực thực tế, không đếm lại những màn đã có.

## 1. Giỏ đi chợ thật — P1, M

**Giá trị:** biến công thức thành danh sách mua sắm dùng được hằng ngày.

- Chi tiết món → Thêm vào giỏ → chọn nguyên liệu, khẩu phần → xác nhận.
- Lưu danh sách của tài khoản, thêm món cần mua thủ công, chỉnh lượng, đánh dấu,
  bỏ đánh dấu và xóa; giữ dữ liệu qua khởi động lại và đồng bộ thiết bị.
- Gộp cùng nguyên liệu khi có cùng đơn vị chuẩn. Không cộng g với quả, không
  suy ra lượng tồn kho từ việc chỉ đánh dấu đã có nguyên liệu.
- Dòng nguyên liệu tự do hoặc nêm theo khẩu vị giữ riêng, cho người dùng chỉnh.
- Hoàn tất đi chợ chỉ xác nhận danh sách đã mua; chưa tự cộng vào tồn kho.

**Điểm vào:** tab Đi chợ và Chi tiết món. **Dữ liệu dự kiến:** danh sách/items
thuộc UID, ingredientId tùy chọn, lượng/đơn vị, checked, recipeId nguồn và metadata
tối thiểu để danh sách vẫn đọc được nếu công thức không còn công khai.

**Nghiệm thu:** thêm nhiều công thức không nhân đôi dòng hợp lệ, tỷ lệ khẩu phần
đúng, retry không thêm trùng, đổi tài khoản không lộ danh sách trước.

## 2. Lên thực đơn tuần — P1, M

**Giá trị:** giảm việc phải nghĩ hôm nay nấu gì và giúp chuẩn bị nguyên liệu trước.

- Lịch bảy ngày, chia sáng/trưa/tối; chọn công thức cho từng bữa và số người ăn.
- Thêm, đổi, bỏ món; sao chép một ngày; tổng hợp nguyên liệu đã chọn sang giỏ.
- Bản đầu chọn món thủ công, không gọi là thực đơn AI hoặc tối ưu dinh dưỡng.

**Điểm vào:** Home và mục Thực đơn trong khu vực cá nhân; chưa thêm tab chính.
**Dữ liệu:** ngày lịch địa phương, múi giờ, bữa, recipeId và servings. Không dùng
UTC midnight làm khóa ngày một cách ngầm định.

**Phụ thuộc:** giỏ đi chợ thật cho thao tác tổng hợp. **Nghiệm thu:** không đổi
ngày bữa ăn do chuyển múi giờ/thiết bị, công thức bị gỡ có trạng thái rõ ràng,
thêm vào giỏ lặp lại có cơ chế phát hiện/kiểm soát trùng.

## 3. Tủ lạnh có số lượng và hạn dùng — P2, L

**Giá trị:** quản lý đồ đang có và ưu tiên sử dụng nguyên liệu sắp hết hạn.

- Mỗi nguyên liệu có nhiều lô nếu ngày mua/hạn dùng khác nhau; lượng và đơn vị
  có thể chưa biết. Hạn dùng do người dùng nhập, không tự suy đoán.
- Sửa, sử dụng bớt hoặc bỏ một lô; bộ lọc Sắp hết hạn và Đã quá ngày đã nhập.
- Gợi ý món dựa trên các nguyên liệu cần dùng trước. Việc chọn món không tự
  trừ kho; đề nghị xác nhận lượng dùng sau khi hoàn tất nấu.
- Bản đầu hiển thị nhắc trong app; thông báo ngoài app là phần mở rộng riêng.

**Điểm vào:** tab Tủ lạnh. **Dữ liệu:** lots có ingredientId, amount/unit tùy chọn,
expiresOn tùy chọn; cần phiên bản schema và đường nâng cấp từ danh sách ID cũ.

**Nghiệm thu:** dữ liệu cũ vẫn đọc được, không trừ âm, không cộng sai đơn vị,
không dùng nhãn ngày để khẳng định thực phẩm chắc chắn an toàn.

## 4. Bộ sưu tập công thức — P1, S–M

**Giá trị:** tìm lại món đã lưu theo nhu cầu, thay cho một danh sách dài.

- Tạo bộ sưu tập như Bữa sáng, Món cuối tuần; đổi tên, xóa và thêm/bỏ món.
- Một món thuộc nhiều bộ sưu tập; thao tác lưu nhanh hiện tại vẫn giữ nguyên.
- Bộ sưu tập mặc định riêng tư. Xóa bộ sưu tập không tự bỏ lưu tất cả món.

**Điểm vào:** Hồ sơ → Đã lưu và menu của Chi tiết món. **Dữ liệu:** collection
thuộc UID, tên và các recipeId; không sao chép document công thức công khai.

**Nghiệm thu:** trạng thái lưu đồng bộ Home/Chi tiết/Hồ sơ, xử lý món bị gỡ,
không mất các món đã lưu trước khi có chức năng này.

## 5. Nhật ký nấu ăn và ghi chú riêng — P1, M

**Giá trị:** nhớ món đã nấu, kinh nghiệm lần trước và công thức muốn nấu lại.

- Hoàn tất nấu → xác nhận lưu lần nấu, ngày, khẩu phần và ghi chú riêng.
- Lịch sử theo ngày hoặc món; sửa ghi chú/xóa bản ghi; mở lại công thức.
- Bản đầu dùng ghi chú văn bản; ảnh thành phẩm để giai đoạn sau nhằm giảm
  phạm vi upload/lưu trữ và quản lý ảnh.
- Số lần đã nấu lấy từ nguồn nhất quán; không cho client tự ghi số tổng bất kỳ
  vào cookedCount đang được rules bảo vệ.

**Điểm vào:** kết thúc chế độ nấu và Hồ sơ. **Dữ liệu:** cookingSessionId,
recipeId, thời điểm, servings và note; ghi theo idempotency key của lần nấu.

**Nghiệm thu:** bấm Hoàn tất/thử lại không ghi hai lần, ghi chú chỉ chủ sở hữu
đọc được, đóng app rồi mở lại vẫn thấy lịch sử.

## 6. Bộ hẹn giờ theo bước nấu — P1, M

**Giá trị:** hỗ trợ thao tác ngay trong bếp, giảm chuyển qua ứng dụng đồng hồ.

- Bước có thời gian → đặt hẹn giờ → bắt đầu/tạm dừng/tiếp tục/hủy.
- Có thể có nhiều timer; hiển thị tên món và bước để không nhầm.
- Lưu thời điểm kết thúc và trạng thái; khi app trở lại tính từ thời gian thực,
  không dựa vào số tick Timer đã chạy trong nền.
- MVP bảo đảm hiển thị/khôi phục trong app. Báo chuông khi app đóng cần thiết
  kế notification theo nền tảng, xin quyền và kiểm thử riêng trước khi cam kết.

**Điểm vào:** chế độ nấu. **Dữ liệu:** trạng thái local theo cooking session.
**Nghiệm thu:** chuyển màn/xoay máy/đưa app ra nền không reset timer; không tự
chuyển bước hay dừng timer khác khi người dùng tạm dừng đọc công thức.

## 7. Tải công thức để nấu offline — P2, L

**Giá trị:** xem lại hướng dẫn đã tải khi mạng yếu trong lúc nấu.

- Người dùng chủ động tải công thức đang công khai; gồm nội dung và ảnh cần
  thiết. Có màn quản lý tải về, dung lượng và xóa bản tải.
- Hiển thị Offline và thời điểm cập nhật; có thể dùng timer và đọc ghi chú
  local, nhưng thao tác cần máy chủ không được báo thành công giả.
- Bản đầu chỉ tải đọc; chưa hỗ trợ gửi đánh giá hay chỉnh dữ liệu cloud offline.

**Điểm vào:** Chi tiết món và khu vực cá nhân. **Dữ liệu:** cache local có phiên
bản, thời điểm đồng bộ và phạm vi UID khi gắn dữ liệu riêng tư.

**Nghiệm thu:** chế độ máy bay vẫn mở được món đã tải; logout xóa dữ liệu riêng;
khi online kiểm tra lại trạng thái công thức. Không cam kết thu hồi tức thì bản
cache trên một thiết bị hoàn toàn offline khi bài bị gỡ.

## 8. Theo dõi tác giả và bảng tin Đang theo dõi — P2, M–L

**Giá trị:** giúp quay lại với các tác giả có phong cách nấu phù hợp.

- Theo dõi/bỏ theo dõi từ hồ sơ công khai; xem và quản lý danh sách theo dõi.
- Home có bộ chọn Khám phá/Đang theo dõi, chỉ lấy bài approved, có phân trang.
- MVP là bảng tin khi mở app; chưa gửi push cho mọi bài mới, tránh mở rộng
  hạ tầng thông báo ngay ở bản đầu.

**Dữ liệu:** quan hệ UID → authorId, chống tự theo dõi/trùng; không dựng số người
theo dõi nếu chưa có nguồn tổng hợp đáng tin cậy. Cần chọn chiến lược query cho
danh sách tác giả dài, không giả định Firestore truy vấn không giới hạn.

**Nghiệm thu:** bỏ theo dõi cập nhật feed, bài chưa duyệt không lọt ra ngoài,
khóa/gỡ nội dung được áp dụng theo contract truy cập hiện tại.

## 9. Đánh giá và nhận xét công thức — P3, L

**Giá trị:** phản hồi thực tế để người khác chọn món và tác giả cải thiện hướng dẫn.

- Người dùng active gửi 1–5 sao và nhận xét; mỗi tài khoản có một đánh giá
  đang hiệu lực cho mỗi công thức, được sửa/xóa đánh giá của mình.
- Không tự đánh giá bài của chính mình; có giới hạn độ dài và chống gửi trùng.
- Có báo cáo và cơ chế ẩn nội dung không phù hợp trước khi mở rộng công khai.
- Điểm trung bình/số lượt đánh giá được tính bằng logic đáng tin cậy. Tách điểm
  fixture/cũ khỏi điểm người dùng; không lấy trung bình hai nguồn tùy tiện.

**Điểm vào:** Chi tiết món và kết thúc nấu. **Dữ liệu:** review riêng liên kết
recipeId, aggregate do trusted service quản lý. Cần bổ sung hạ tầng tổng hợp và
công cụ xử lý báo cáo; đây là dependency ngoài phần Flutter app.

**Nghiệm thu:** retry/sửa/xóa không làm sai số tổng, không đọc/ghi đánh giá của
bài ngoài quyền truy cập, nội dung bị ẩn không còn trong danh sách công khai.

## 10. Chia sẻ công thức bằng liên kết — P1, S–M

**Giá trị:** gửi món cho bạn bè và đưa người mới đến đúng công thức.

- Chi tiết món → Chia sẻ → share sheet của hệ điều hành hoặc Sao chép liên kết.
- Người nhận mở trang đúng món trên web; cấu hình app links/universal links
  cho nền tảng native khi có domain phù hợp.
- Không ép đăng nhập chỉ để xem món công khai. Liên kết bài bị gỡ/chưa duyệt
  đưa tới trạng thái không khả dụng, không lộ dữ liệu tác giả riêng tư.
- MVP dùng URL công khai ổn định. Preview ảnh/tên khi gửi qua mạng xã hội chỉ
  cam kết sau khi có metadata do máy chủ trả về; không phụ thuộc Flutter tự
  render để crawler đọc và chưa hứa mở lại đúng món sau cài app mới.

**Phụ thuộc:** domain HTTPS và routing; metadata/link association là phần việc
hosting/hạ tầng nếu cần. **Nghiệm thu:** sao chép/share mở đúng ID, refresh URL
trực tiếp hoạt động, có fallback khi thiết bị không hỗ trợ share sheet.

## Thứ tự triển khai đề xuất

1. **Đợt A — Tạo giá trị ngay:** giỏ đi chợ thật (1), bộ sưu tập (4), chia sẻ (10).
2. **Đợt B — Hoàn chỉnh chu trình nấu:** thực đơn tuần (2), nhật ký (5), timer (6).
3. **Đợt C — Dùng lâu dài:** tồn kho theo lô (3), tải offline (7).
4. **Đợt D — Cộng đồng:** theo dõi (8), đánh giá (9); chỉ mở review sau khi có
   tổng hợp điểm và xử lý báo cáo đáng tin cậy.

Chu trình ưu tiên: chọn món → lên thực đơn → giỏ đi chợ → nấu có timer → lưu
nhật ký. Chia sẻ và bộ sưu tập có thể bàn giao độc lập, không phải chờ xã hội hóa.

## Quy tắc chung khi bắt đầu từng chức năng

- Chốt luồng, trạng thái rỗng/lỗi/loading, dữ liệu và tiêu chí nghiệm thu trước.
- Theo Screen/Content/Widget → Cubit → repository/service; giữ widget ngoài
  Firestore và giữ router ngoài Cubit. Không thêm tab chính cho từng chức năng.
- `recipes/{id}` vẫn là nguồn công thức duy nhất; giữ lifecycle và quyền banner
  hiện có. Các collection bổ sung là dữ liệu người dùng hoặc quan hệ, không phải
  bản sao để tạo một hệ xuất bản khác.
- Với dữ liệu Firebase mới, thiết kế rules/index/query, giới hạn đọc và retry
  cùng chức năng; kiểm thử emulator trước, không dùng production làm dữ liệu thử.
- Cần dữ liệu cũ tương thích, auth/session isolation, idempotency và xử lý bài
  bị gỡ. Các thao tác thêm tài nguyên phải có đường xóa tương ứng.
- Mobile/tablet cùng contract; kiểm tra bàn phím, xoay máy, chữ lớn, analyzer,
  focused tests và regression. Chưa chốt số ngày khi contract/dependency chưa rõ.

**Phạm vi đã chốt:** bỏ mục 1. Các chỗ đề xuất chuyển sang giỏ ở mục 2 không áp dụng;
thay bằng tổng hợp chỉ đọc và sao chép văn bản. Không tạo collection giỏ mới.
