# Đăng món

Trình bày nhóm (26/11/2026): dùng nhãn nhóm nhỏ, đậm vừa và màu trung tính theo
`AppMenuSection` như Bếp của tôi. Các phần Thông tin món ăn, Thông số chế biến,
Danh mục, Bữa ăn, Khẩu phần, nhóm nguyên liệu, từng bước nấu và Xem trước không
bọc card/khung riêng. Bỏ tiêu đề trang trí lớn và các dòng hướng dẫn chọn danh mục
bị lặp; giữ nhãn trường, giải thích định lượng cần thiết, lỗi validation và trạng
thái nháp. Thay đổi chỉ ở trình bày; không bỏ field, không đổi payload, thao tác
thêm/sửa/xóa, ảnh, lưu nháp hoặc gửi duyệt.

Xác minh: 42 test liên quan Đăng món/biến tấu/ảnh/chi tiết đạt sau khi cập nhật
assertion cho tiêu đề trang trí đã bỏ. Capture ở 390×844, 800×1100 và 1024×768
đạt; đã xem ảnh mobile và tablet trong `build/ui_ux/flat-editor/`. Analyzer còn
5 issue sẵn có ngoài source thay đổi. Chưa phát hành Hosting trong đợt chỉnh UI này.

Màn `/recipes/new` được mở từ nút `+` của thanh điều hướng mobile/tablet.
`AppAppBar` nằm trong `core/widgets`, dùng lại cho các màn form/chi tiết. Màn Đăng
món chỉ có luồng tác giả, không chứa giao diện quản trị hay tab duyệt bài.

Luồng tác giả gồm bốn bước: **Thông tin → Nguyên liệu → Cách nấu → Xem trước**.
Thông tin gồm ảnh bìa, tên/mô tả món, thời gian chuẩn bị/nấu, khẩu phần, độ khó
và nhiều dịp dùng món. Nguyên liệu chia theo nhóm có thể thêm, đổi tên hoặc xóa;
xóa nhóm chuyển nguyên liệu về nhóm đầu tiên, giữ nguyên định lượng và ID dòng.
Khẩu phần là số người tương ứng với lượng tác giả nhập, chưa tự thay đổi định lượng.
Mỗi bước nấu có nội dung bắt buộc và tên, thời gian, mẹo, ảnh minh họa tùy chọn.
Có thể đổi thứ tự bước nấu, xóa bước và thêm ghi chú bảo quản chung.

Từ 26/11/2026, bài đăng hỗ trợ tối đa **10 ảnh món ăn**: một ảnh bìa và tối đa
9 ảnh bổ sung. Nút **Thêm ảnh** chọn nhiều ảnh trong một lần; mỗi ảnh vẫn giới
hạn 8 MB, resize tối đa 1920 px và xác minh decode như ảnh bìa. Có thể xóa từng
ảnh hoặc chọn **Làm ảnh bìa**; xóa bìa đưa ảnh bổ sung đầu tiên lên làm bìa.
Hủy chọn hoặc chọn vượt số chỗ còn lại giữ nguyên danh sách trước đó.
Chụp ảnh/đổi bìa vẫn dùng hành vi hiện có; ảnh từng bước nấu là phần riêng.

`RecipeDraft.photos` / `RecipeContent.photos` lưu ảnh bổ sung theo thứ tự,
không lặp ảnh bìa trong danh sách. Codec, fingerprint nội dung, upload tuần tự,
nháp, biến tấu và tải offline đều giữ danh sách này. Firestore chỉ nhận ảnh
Cloudinary đã upload, không nhận bytes. Cache upload theo bytes vẫn giữ đúng
ID của mỗi ô ảnh để các lựa chọn trùng file không làm mất định danh.
Home dùng gallery vuốt ngang với hàng chấm nằm hẳn dưới ảnh, trên hàng tim/chia sẻ;
chấm đang chọn dùng màu nhấn và chấm còn lại dùng màu trung tính. Không hiện số ảnh
hoặc hai nút chuyển ảnh. Có thể chạm chấm để chọn ảnh. Xem trước và Chi tiết món
giữ số ảnh và nút trước/sau cho desktop. Bài cũ thiếu `photos` được hiểu là danh sách bổ sung rỗng;
banner và thumbnail vẫn dùng ảnh bìa. Luồng duyệt và trạng thái bài không đổi.

Phần Thông tin có bốn danh mục chọn nhiều: Eat Clean, Nấu nhanh, Món nước,
Món chay. `RecipeCategory` dùng ID ổn định trong `RecipeDraft` và
`RecipeContent.categories`, giữ nguyên qua lưu nháp, gửi duyệt, xem trước và
Chi tiết món. Danh mục không bắt buộc; dữ liệu cũ thiếu trường này đọc thành
tập rỗng. Tất cả/Món mới chỉ là bộ lọc khám phá, không phải lựa chọn của tác giả.
Xem [recipe_search.md](recipe_search.md) cho quy tắc tìm kiếm và lọc.

`RecipeEditorCubit` sở hữu bước hiện tại, dữ liệu form, validation, thao tác
lưu/gửi và kiểm tra thay đổi chưa lưu. Chuyển tiếp kiểm tra dữ liệu các phần
trước đó; chỉ được mở lại các bước đã đến, không bỏ qua bước chưa hoàn thành.
Xem trước dùng chính `RecipeDraft`, có hành động chỉnh sửa từng phần. Sau khi
sửa, chuyển đến xem trước vẫn kiểm tra lại những phần trước đó. Back hệ thống,
AppBar và nút Bước trước quay về bước trước; rời bước đầu mới kiểm tra bỏ nháp.
Đổi bước không đánh dấu dữ liệu đã thay đổi. Mở lại nháp bắt đầu ở bước thông tin.

Screen chỉ nối service, thông báo, điều hướng và xác nhận rời form; widget đều
Stateless, chia thành progress, form từng phần, ảnh, tip, preview và thanh hành động.
Các dòng nguyên liệu/bước dùng ID ổn định để xóa hoặc đổi thứ tự một dòng không
làm chuyển nội dung controller/ảnh sang dòng khác. `IngredientPickerCubit` tiếp
tục sở hữu riêng trạng thái sheet chọn nguyên liệu.

Nguyên liệu được thêm/sửa qua bottom sheet riêng. `IngredientPickerCubit` quản lý
tìm kiếm qua service (debounce, bỏ response cũ, lỗi/thử lại), chọn danh mục,
số lượng nguyên từ 1 đến 100.000, đơn vị, ghi chú và lựa chọn "Vừa đủ". Hủy sheet không thay
đổi form; xác nhận mới cập nhật một dòng và kiểm tra trùng. Có thể xóa hết dòng,
nhưng gửi duyệt yêu cầu ít nhất một nguyên liệu.

`features/ingredients` sở hữu danh mục dùng chung cho Tủ lạnh và Đăng món, inject
qua `IngredientCatalogService`. Production tải `catalogs/ingredients` từ Firestore;
fixture `assets/mock/ingredients.json` phục vụ kiểm thử. `fridge.json` chỉ còn tồn kho và gợi ý món.
Service gộp request tải danh mục và cache trong phiên. Tìm kiếm hỗ trợ
không dấu và alias (đậu phụ/đậu hũ, thịt lợn/thịt heo). Thêm tên trùng chính xác
với alias sẽ chọn nguyên liệu chuẩn thay vì tạo một nguyên liệu tự nhập.

`RecipeIngredientDraft.id` là ID dòng; `ingredientId` là ID danh mục, nullable
khi người dùng tự nhập nguyên liệu chưa có. `amount` là số, `unitId` là ID đơn
vị; tên và nhãn đơn vị chỉ là snapshot hiển thị. `toTaste` bỏ amount/unit khỏi
payload. `groupId` liên kết đến `RecipeDraft.ingredientGroups`. Ghi chú không nằm chung trong lượng dùng. Service gửi duyệt đối chiếu
ID và đơn vị với danh mục. Chưa tự quy đổi giữa thìa, gram, ml hoặc tính dinh
dưỡng; các phép tính đó cần dữ liệu quy đổi riêng theo nguyên liệu.

`RecipeEditorService` được inject theo UID ở app. Production dùng
`FirestoreRecipeEditorService` → `RecipeImageUploader` / `RecipeAuthoringRepository`;
HTTP và Firestore nằm ở adapter, không nằm trong Cubit/widget.
Lưu nháp chấp nhận form chưa hoàn tất, tải ảnh lên Cloudinary rồi ghi
`users/{uid}/recipe_drafts/current`; mở lại sẽ khôi phục URL ảnh và dữ liệu form.
Gửi duyệt kiểm tra tên, ảnh, thời gian, khẩu phần, nguyên liệu và bước nấu trước
khi upload. Gửi thành công đóng form, tạo bài `pending` và xóa nháp bằng transaction.
Snapshot lưu nháp không đánh dấu những thay đổi phát sinh trong request là đã lưu.
Revision chặn ghi đè từ phiên khác; submission ID và content hash giúp thử lại
sau khi mất phản hồi mà không tạo bài trùng. Nút hành động hiển thị tiến độ upload/lưu/gửi.

Khi gửi, form chuyển qua `RecipeDraft.toRecipeContent()` rồi được kiểm tra bằng
reader `RecipeContent` dùng chung với Chi tiết món và chế độ nấu. Giới hạn field,
enum, nhóm và ảnh nằm trong `features/recipes`; editor không sở hữu một schema
công thức xuất bản riêng. Tất cả bài nằm trong `recipes`; pending/rejected chỉ tác giả
đọc được, approved được đọc công khai. Client không có quyền tự duyệt. Admin chỉ
cần đổi status thành approved trên cùng document để Home lấy realtime. “Bài đã gửi” trong Cài đặt
hiển thị trạng thái và lý do từ chối; sửa bài bị từ chối tạo phiên bản mới, giữ lịch sử cũ.
Xem [RECIPE_PUBLISHING.md](RECIPE_PUBLISHING.md) cho contract, duyệt bài và vận hành.
Xem `recipe_detail.md` cho luồng đọc/nấu. Mock service chỉ phục vụ test/fixture.

`RecipeCoverPicker` tách khỏi Cubit để kiểm thử và thay implementation, dùng cho
cả ảnh bìa và ảnh minh họa bước nấu. Hủy hoặc chọn ảnh lỗi giữ ảnh trước đó. Adapter
`image_picker` chọn ảnh thư viện, giới hạn dung lượng, kiểm tra ảnh bằng codec có
kích thước giải mã nhỏ và phục hồi kết quả picker bị gián đoạn trên Android.
Ảnh chọn được giữ bằng bytes trong form; trước khi lưu Firestore phải upload và
thay bằng HTTPS URL/publicId. Không ghi base64 hoặc đường dẫn tạm vào document.
iOS đã khai báo mục
đích truy cập thư viện ảnh; không yêu cầu camera/microphone vì màn này chỉ chọn ảnh.

Các test bao phủ validation, gõ/xóa/nhập lại, thêm/xóa dòng, chọn/hủy/lỗi ảnh,
lưu/gửi bất đồng bộ, quay lại khi chưa lưu, khôi phục nháp, định tuyến nút `+`,
validation từng bước, chỉnh sửa từ xem trước, nhóm nguyên liệu, giữ dữ liệu khi
đổi thứ tự bước và layout màn hẹp/chữ lớn.

Form lấy Home làm chuẩn: nền `AppColors.background`, nhóm thông tin và bước nấu
dùng `AppCard` trắng bo góc, tiêu đề dùng `AppSectionHeader`, khoảng cách nhóm 16px.
Thanh bước dùng nhãn chữ và vạch tiến trình mảnh. Menu dấu ba chấm gom thao tác
nhóm/bước nấu; bỏ icon trang trí, badge tròn và icon kiểm tra ở bản xem trước.
Ảnh bìa đặt ở đầu, nguyên liệu hiển thị dạng dòng có thể chạm để sửa. Tip dùng nền
trung tính, thông số xem trước gộp thành một khối chữ. Màu cam dành cho hành động
và lựa chọn hiện tại.
Không sao chép palette tím của bản thiết kế. Không hiển thị AI, video, timer hay
thời hạn duyệt cố định khi chưa có service tương ứng.

Tiêu đề/action dùng `AppSectionHeader` và `AppTextAction` tách từ Home; tìm nguyên
liệu dùng cùng `AppSearchBar` với Home/Tủ lạnh. `AppTextField` và dropdown nhận
style từ `AppTheme`. Xem `shared_ui.md` cho danh sách component và nơi sử dụng.

Tải form dùng `RecipeEditorSkeleton`; tải/tìm nguyên liệu dùng `SkeletonListRows`.
`AppSkeleton` có một ticker cho cả bố cục, dừng khi route bị ẩn, app rời foreground
hoặc người dùng bật giảm chuyển động. Skeleton chặn thao tác và có nhãn đọc màn
hình "Đang tải". Loading khi lưu/gửi vẫn thuộc nút hành động.

Biến tấu và đăng lại từ bài công khai: xem [RECIPE_REMIX.md](RECIPE_REMIX.md) cho luồng nháp, ghi nguồn, schema và kiểm thử.
