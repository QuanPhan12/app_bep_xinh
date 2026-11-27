# Số tương tác trên post

## Cách tính

- Tim đếm số tài khoản đang lưu món ở `users/{uid}/favorites/{recipeId}`. Bỏ lưu
  giảm một; giữ nguyên chức năng lưu món.
- Nút cmt giữ màn Đánh giá cộng đồng theo lựa chọn của người dùng. Số đếm đọc
  realtime từ `recipes/{id}/ratings/summary.count`: chỉ đánh giá đã duyệt, kể cả
  đánh giá chỉ có sao. Sửa/xóa/ẩn đánh giá cập nhật tổng qua luồng moderation cũ.
- Share đếm số tài khoản đã chia sẻ hoặc sao chép link ít nhất một lần, mỗi tài
  khoản/món tính tối đa một. Hủy sheet không tính. Trên web plugin trả unavailable
  sau khi Web Share/mailto nhận yêu cầu, nên tính lần bàn giao đó; native unavailable
  không tính. Đây không phải xác nhận người nhận đã nhận hoặc mở liên kết.

Khách vẫn dùng chia sẻ nhưng không ghi bộ đếm do chưa có danh tính tài khoản.
Lỗi ghi thống kê không chặn việc share/copy đã hoàn tất; có thể ghi lại ở lần sau
nếu chưa có receipt. Receipt được chấp nhận thì số tăng cùng commit, không tăng giả
ngay khi bấm nút. Giao dịch ghi số đếm cần kết nối Firestore.

## Dữ liệu và tính nhất quán

`recipes/{id}.engagement` gồm hai số nguyên không âm `likeCount`, `shareCount`.
Đây là metadata ngoài `content`, không vào contentHash hay payload tác giả gửi duyệt.
`RecipeItem` đọc/copy/equality giữ số liệu; nguồn published realtime cập nhật Home.
Feed theo dõi/tìm kiếm/hồ sơ lấy số tim/share tại lần tải của luồng hiện có.

`FirestoreRecipeFavoritesService.setFavorite` đọc favorite của chính mình trong
transaction, chỉ tạo/xóa khi trạng thái thực sự đổi; cùng commit increment số tim
trên recipe. ID công thức đăng mới dùng r_, không cần đọc nội dung recipe để bỏ tim
khi bài bị ẩn. Với ID bài mẫu cũ, chỉ theo dõi tổng khi có document recipe thật.

`RecipeShareRecorder` đọc receipt `recipes/{id}/shares/{uid}` của chính mình.
Chưa có receipt thì tạo `{uid,channel,createdAt}` và increment shareCount trong cùng
transaction. Đã có thì kết thúc không ghi, kể cả lần đầu sao chép rồi lần sau share.
`RecipeSharingService` nhận callback qua KitchenScope; không gọi Firestore từ widget.

Rules dùng `get/getAfter` kiểm tra trạng thái favorite/receipt và recipe trước/sau:
chỉ thay engagement, chỉ tăng/giảm đúng một theo thao tác thật và giữ nguyên tổng
còn lại. Favorite/receipt cũng yêu cầu tổng đi cùng commit. Không thể sửa số độc lập,
ghi sai delta, mượn danh UID khác, hoặc cộng lại một receipt đã tồn tại. Cho phép bỏ
tim trên bài bị ẩn; thêm tim/chia sẻ yêu cầu bài approved. Receipt chỉ chủ tài khoản
active được get/create; không list/update/delete, không public danh sách người lưu.
Admin client cũng không có quyền tự đặt tổng tùy ý.

Phần cmt dùng listener có vòng đời riêng trong `PostCommentAction`: trạng thái chưa
nhận dữ liệu hiện —, lỗi giữ số đã biết; không hiện số 0 giả khi chưa tải được.
Widget đóng thì hủy subscription. Mock/preview không có KitchenScope dùng số fixture.
Các nút giữ icon đơn sắc, có tooltip, số đầy đủ trong semantics; từ 1000 hiển thị
gọn k/M. Hàng nút tự xuống dòng ở màn hẹp/chữ lớn.

## Phát hành và số liệu cũ

Project hiện dùng Spark. Firebase từ chối deploy Cloud Functions do thiếu Blaze;
thiết kế cuối dùng giao dịch/rules Firestore, không có trigger hoặc yêu cầu đổi gói.

`tool/backfill_recipe_engagement.cjs` mặc định chỉ đọc báo số recipe/favorite.
`--apply` tính lại số từ dữ liệu nguồn trong transaction rồi chỉ sửa engagement,
giữ nội dung công thức, favorite, review và receipt. Chạy lại không tăng trùng.
Giao dịch đọc lại parent và truy vấn nguồn; tương tác từ client mới đồng thời cũng
sửa parent nên xung đột sẽ retry. Tool dùng IAM qua phiên Firebase CLI, không in
UID, email hoặc nội dung bài.

```powershell
npm.cmd exec --yes --package=firebase-tools@15.34.2 -- firebase deploy --only firestore:rules --project bepxinh-b0be7
npm.cmd exec --yes --package=firebase-tools@15.34.2 -- node tool/backfill_recipe_engagement.cjs
npm.cmd exec --yes --package=firebase-tools@15.34.2 -- node tool/backfill_recipe_engagement.cjs --apply
npm.cmd exec --yes --package=firebase-tools@15.34.2 -- node tool/backfill_recipe_engagement.cjs --verify
```

Cần phát hành/cài client mới cùng thay đổi rules: bản cũ ghi favorite công thức thật
mà không cập nhật tổng cùng commit sẽ bị từ chối. Hot restart app phát triển để
KitchenScope tạo lại callback share; hot reload riêng UI không thay instance service
đã tạo. Web cần build/phát hành bản mới và tải lại trang; APK cũ cần cập nhật.

Không cần index mới, không đổi schema RecipeContent hoặc luồng duyệt đánh giá.
Tham khảo [Firestore atomic writes và getAfter](https://firebase.google.com/docs/firestore/manage-data/transactions#data_validation_for_atomic_operations).

## Kiểm chứng và phát hành 27/11/2026

- Toàn bộ Flutter: 414 test đạt, 4 skip. Gồm số đếm, guard tim, màn 320/844 px
  chữ 200%, cập nhật cmt sau snapshot/lỗi và hủy listener khi đóng widget.
- Emulator demo: 57 kiểm tra Auth/Firestore cũ và 28 kiểm tra atomic engagement
  đạt. SDK Flutter web thật xác nhận lưu/bỏ tim, không tăng trùng khi lưu lại,
  copy rồi share cùng tài khoản chỉ tính một, cùng kiểm tra cô lập tài khoản cũ.
- Build web release và APK debug đạt. Đã xem ảnh mobile có số cạnh ba nút ở
  `build/ui_ux/post-counts/`; callback/semantics và màn lớn được kiểm tra bằng test.
- Rules đã phát hành, ruleset `300eea8b-9a9f-48a0-8b25-ce108bc65d55`.
  Đồng bộ 14 document recipe từ 15 favorite hiện có; verify read-only transaction
  xác nhận cả 14 tổng khớp nguồn. Tool không sửa favorite hoặc nội dung bài.
- Web Hosting version `1899716c4e447c21`, phát hành lúc 11:16:42 UTC+7. Hash
  main.dart.js và empty_state.webp live khớp artifact; Android assetlinks tiếp tục
  trả JSON đúng. Bản APK có cập nhật ở `build/app/outputs/flutter-apk/app-debug.apk`.
- Chưa bấm share sheet trên điện thoại thật. Share/copy outcome được kiểm tra qua
  test; ghi receipt/tổng được xác minh bằng SDK web thật trên emulator.
