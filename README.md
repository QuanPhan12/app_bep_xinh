# Bếp Xinh — Dữ liệu Firebase

Giao diện hiện tại: [theme và component gốc port từ Sollume](docs/SOLLUME_UI_PORT.md).
Quản lý bài đăng: [quyền ẩn/xóa, lịch sử và phát hành](docs/RECIPE_VISIBILITY.md).
Báo cáo món: [luồng gửi và xử lý trên admin](docs/RECIPE_REPORTS.md).
Biến tấu công thức: [luồng đăng lại có điều chỉnh và ghi nguồn](docs/RECIPE_REMIX.md).

Mô tả các trường **thực sự được đọc/ghi trên Firebase** theo source ngày 16/11/2026.
Project cấu hình: `bepxinh-b0be7`. Các bảng dưới đây mô tả schema, không phải bản xuất
dữ liệu người dùng từ production.

## 1. Quy ước

| Ký hiệu | Ý nghĩa |
|---|---|
| `uid` | UID tài khoản trong Firebase Authentication |
| `recipeId` | ID document công thức; bài gửi mới có dạng `r_<Firestore auto ID>` |
| `Timestamp` | Kiểu thời gian Firestore, không phải chuỗi ngày tháng |
| `server timestamp` | Ghi bằng `FieldValue.serverTimestamp()` |
| `T \| null` | Trường cho phép giá trị `null` |
| Map | Object có các cặp khóa/giá trị |
| List | Mảng dữ liệu |

Các trường `DateTime` trong model Dart được codec chuyển từ `Timestamp` khi đọc.
Các `Set` của Dart được ghi thành List hoặc Map tùy schema bên dưới.

## 2. Danh sách collection/document

```text
users/{uid}
  favorites/{recipeId}
  fridge/current
  recipe_drafts/current
  notification_reads/{recipeId}_{status}

recipes/{recipeId}
  visibility_events/{eventId}

catalogs/ingredients

conversations/{conversationId}
  messages/{messageId}

recipe_moderation_events/{recipeId}     # Portal admin/moderator hoặc công cụ IAM ghi
recipe_reports/{uid}:{recipeId}        # Báo cáo món; reporter đọc riêng, staff xem và admin xử lý
```

`current` và `ingredients` là **ID document cố định**, không phải collection.
Ví dụ `users/uid_a/fridge/current` gồm collection `users`, document `uid_a`,
subcollection `fridge` và document `current`.

## 3. Tài khoản — `users/{uid}`

Model: [UserProfile](lib/features/profile/models/user_profile.dart).
Ghi dữ liệu ban đầu: [FirestoreUserStore](lib/core/services/firestore_user_store.dart).

| Trường | Kiểu Firestore | Giá trị/ý nghĩa |
|---|---|---|
| `schemaVersion` | Integer | Document mới là `1`; model còn đọc được dữ liệu cũ thiếu trường này như phiên bản `0` |
| `id` | String | Bằng UID và bằng ID document; không dùng email làm khóa |
| `name` | String | Tên hiển thị, 1–60 ký tự; khởi tạo từ Auth displayName hợp lệ, nếu không dùng `Người yêu bếp` |
| `handle` | String | Khởi tạo `bep_<uid>`; tối đa 132 ký tự |
| `bio` | String | Giới thiệu, tối đa 200 ký tự; ban đầu `""` |
| `showBio` | Boolean | Có hiển thị giới thiệu hay không; ban đầu `true` |
| `avatarUrl` | String hoặc null | URL HTTPS, tối đa 2.048 ký tự; ban đầu `null` |
| `cookedCount` | Integer | Số lần nấu được lưu trên tài khoản, không âm; ban đầu `0` |
| `role` | String | `user`, `moderator`, `admin`; ban đầu `user` |
| `status` | String | `active`, `locked`; ban đầu `active` |
| `createdAt` | Timestamp | Thời điểm tạo, server timestamp |
| `updatedAt` | Timestamp | Thời điểm ghi/cập nhật, server timestamp |
| `lastLoginAt` | Timestamp hoặc null | Ban đầu `null`; app hiện chưa tự cập nhật trường này sau mỗi lần đăng nhập |
| `lockedAt` | Timestamp hoặc null | Thời điểm khóa tài khoản; ban đầu `null` |
| `lockReason` | String hoặc null | Lý do khóa, tối đa 500 ký tự; ban đầu `null` |

### `status` của tài khoản

| Giá trị | Ý nghĩa | Các trường đi kèm |
|---|---|---|
| `active` | Tài khoản đang hoạt động | `lockedAt = null`, `lockReason = null` |
| `locked` | Tài khoản bị khóa | `lockedAt` phải là Timestamp; `lockReason` có thể null hoặc chuỗi tối đa 500 ký tự |

### `role` của tài khoản

| Giá trị | Ý nghĩa |
|---|---|
| `user` | Người dùng thông thường, giá trị lúc đăng ký |
| `moderator` | Duyệt/từ chối bài, đọc lịch sử; cần status active |
| `admin` | Thêm quyền banner, danh mục và quản lý tài khoản khác; cần status active |

**Lưu ý về quyền và dữ liệu:**

- Người dùng chỉ được cập nhật `name`, `bio`, `showBio`, `updatedAt` của chính mình.
- Portal admin được cập nhật `role`, `status`, `lockedAt`, `lockReason`, `updatedAt`
  của tài khoản khác; không được tự thay quyền/khóa mình. Moderator không có quyền này.
- Client không được tự đổi `role`, `status`, `handle`, tăng `cookedCount` hoặc sửa thông tin khóa.
- Có `role = admin` trong document không đồng nghĩa được cấp quyền IAM để dùng công cụ quản trị.
- Form sửa hồ sơ hiện chỉ sửa tên/giới thiệu; không có thao tác ghi avatar từ form này.
- `avatarAsset` tồn tại trong model để đọc dữ liệu mẫu, **không được ghi vào document user thật**.
- Hoàn tất nấu trong màn chi tiết hiện không tự tăng `users.cookedCount`.

### Dữ liệu thuộc Firebase Authentication

Email, mật khẩu, provider Google và phiên đăng nhập do Firebase Authentication quản lý.
Google dùng cùng UID và schema hồ sơ bên dưới; app không lưu Google ID token/access token
hay mật khẩu Google vào Firestore. Lần đầu tạo hồ sơ role `user`, status `active`;
đăng nhập lại giữ nguyên quyền/trạng thái đã có.
Document `users/{uid}` hiện **không lưu** email, mật khẩu, access token hoặc refresh token.
UID và displayName của Auth được dùng khi khởi tạo hồ sơ Firestore.

## 4. Món đã lưu — `users/{uid}/favorites/{recipeId}`

| Trường | Kiểu | Ý nghĩa |
|---|---|---|
| `recipeId` | String | Bằng ID document favorite, tham chiếu công thức |
| `createdAt` | Timestamp | Server timestamp khi lưu |

- Lưu món: tạo/ghi document này.
- Bỏ lưu: xóa document này.
- Không có field `isFavorite` trong document favorite. Trạng thái lưu được suy ra từ việc document có tồn tại hay không.
- Chỉ tài khoản sở hữu được đọc/ghi. Service nghe `snapshots()` để đồng bộ giữa các màn.

## 5. Tủ lạnh — `users/{uid}/fridge/current`

| Trường | Kiểu | Giá trị/ý nghĩa |
|---|---|---|
| `schemaVersion` | Integer | `1` |
| `ingredientIds` | Map<String, Boolean> | Các ID nguyên liệu đã chọn; mọi giá trị phải là `true`; tối đa 500 khóa |
| `updatedAt` | Timestamp | Server timestamp |

Ví dụ dữ liệu:

```json
{
  "schemaVersion": 1,
  "ingredientIds": {
    "beef_shank": true,
    "egg": true
  }
}
```

`updatedAt` được SDK thêm bằng server timestamp khi ghi. Ví dụ chỉ minh họa cấu trúc;
ID nguyên liệu được chọn phải có trong catalog hiện tại.

Không lưu số lượng, ngày hết hạn hoặc danh sách món gợi ý trong document này.
Món gợi ý được tính từ kho nguyên liệu và công thức đã duyệt. Document chưa tồn tại
được hiểu là kho rỗng. Xóa hết lựa chọn sẽ ghi `ingredientIds: {}`.

## 6. Công thức — `recipes/{recipeId}`

Đây là collection chung cho bài chờ duyệt, được duyệt và bị từ chối.
Không chuyển bài sang collection khác sau khi duyệt.

| Trường | Kiểu | Giá trị/ý nghĩa |
|---|---|---|
| `schemaVersion` | Integer | Bài gửi mới là `2` |
| `id` | String | Bằng ID document, dạng `r_<Firestore auto ID>` với bài tạo từ app |
| `authorId` | String | UID tác giả |
| `author` | Map | Snapshot tác giả: `{id, name, handle}` |
| `isBanner` | Boolean | Có dùng làm banner Home; bài gửi mới luôn `false`, quản trị viên quyết định bật |
| `status` | String | `pending`, `approved`, `rejected`, `hidden`, `deleted` |
| `visibilityEventId`, `visibilityActor`, `visibilityRole` | String, tùy chọn | ID audit, UID và vai trò `author`/`admin` của lần đổi hiển thị gần nhất |
| `visibilityReason`, `visibilityAt` | String hoặc null, Timestamp | Lý do ẩn của admin và thời gian server; xuất hiện sau lần thao tác đầu |
| `revisionOf` | String hoặc null | ID bài bị từ chối mà bài này sửa lại; bài mới bình thường là `null` |
| `content` | Map | Nội dung công thức, xem phần 6.2 |
| `contentHash` | String | SHA-256 của JSON nội dung, 64 ký tự hex; dùng kiểm tra retry/xung đột |
| `catalogVersion` | String | Phiên bản catalog lúc gửi, ví dụ `2026-11-09.v1`; service có fallback `legacy` |
| `submittedAt` | Timestamp | Server timestamp khi gửi |
| `reviewedAt` | Timestamp hoặc null | Thời điểm duyệt; ban đầu `null` |
| `reviewedBy` | String hoặc null | Định danh người/công cụ duyệt; ban đầu `null` |
| `reviewReason` | String hoặc null | Góp ý/lý do từ chối; ban đầu `null`; công cụ duyệt giới hạn 500 ký tự |

### 6.1. `status` của công thức

| Giá trị | Ý nghĩa | Người khác có đọc công khai được không? |
|---|---|---|
| `pending` | Tác giả đã gửi, đang chờ duyệt | Không; tác giả vẫn đọc được bài của mình |
| `approved` | Được duyệt để xuất hiện trong ứng dụng | Có |
| `rejected` | Cần chỉnh sửa trước khi xuất bản | Không; tác giả vẫn đọc được bài của mình |
| `hidden` | Tác giả hoặc admin đã ẩn | Không; tác giả/staff xem trong quản lý bài |
| `deleted` | Chủ bài xóa khỏi app, giữ tombstone và lịch sử | Không; không khôi phục trong app |

Client chỉ tạo bài với `pending`, không được sửa nội dung/tự duyệt hay xóa vật lý.
Chủ bài được ẩn/hiện lại bài tự ẩn và xóa khỏi app; admin được ẩn/hiện lại bài
do admin ẩn. Mỗi lần đổi trạng thái gỡ banner và tạo audit trong cùng transaction.
Duyệt thực hiện bằng portal với role admin/moderator active hoặc công cụ IAM. Sửa bài `rejected` tạo nháp
và bài gửi **ID mới**, với `revisionOf` trỏ về bài cũ.

### 6.2. `content` — nội dung công thức

Model: [RecipeContent](lib/features/recipes/models/recipe_content.dart).

| Trường | Kiểu lưu | Giá trị/giới hạn |
|---|---|---|
| `title` | String | Bắt buộc, tối đa 80 ký tự |
| `isBanner` | Boolean | Khi tác giả gửi luôn `false`; cờ quản trị có hiệu lực là `recipes.isBanner` ở cấp gốc |
| `description` | String | Tối đa 500 ký tự |
| `cover` | Map ảnh | Ảnh bìa bắt buộc khi gửi bài; schema ảnh ở phần 11 |
| `photos` | List<Map ảnh>, tùy chọn | Tối đa 9 ảnh món bổ sung theo thứ tự, không bao gồm bìa; thiếu trường này đọc thành danh sách rỗng. Cùng schema ảnh phần 11 |
| `preparationMinutes` | Integer | 0–240 phút |
| `cookingMinutes` | Integer | 1–720 phút |
| `servings` | Integer | 1–50 khẩu phần |
| `difficulty` | String | `easy`, `medium`, `hard` |
| `meals` | List<String> | `breakfast`, `lunch`, `dinner`, `snack`, `gathering`, `weekend` |
| `categories` | List<String> | `eat_clean`, `quick`, `soup`, `vegetarian` |
| `storageNotes` | String | Ghi chú/bảo quản, tối đa 500 ký tự |
| `ingredientGroups` | List<Map> | 1–8 nhóm nguyên liệu |
| `ingredients` | List<Map> | 1–30 nguyên liệu |
| `steps` | List<Map> | 1–20 bước nấu |

`all` và `new` là bộ lọc khám phá trên UI, không phải giá trị lưu trong `categories`.
App/service kiểm tra các giới hạn và quan hệ ID; không nên hiểu các kiểm tra
schema Firestore hiện tại là đã xác minh đầy đủ mọi trường lồng nhau.

**Mỗi phần tử `ingredientGroups`:**

| Trường | Kiểu | Ý nghĩa |
|---|---|---|
| `id` | String | Khóa nhóm trong công thức, không trùng |
| `name` | String | Tên nhóm, tối đa 60 ký tự |

**Mỗi phần tử `ingredients`:**

| Trường | Kiểu | Ý nghĩa |
|---|---|---|
| `id` | String | Khóa dòng nguyên liệu trong công thức |
| `ingredientId` | String hoặc null | Tham chiếu `catalogs/ingredients.ingredients[].id`; null nếu tự nhập |
| `name` | String | Tên hiển thị, tối đa 80 ký tự |
| `amount` | Number hoặc null | Lượng dùng, lớn hơn 0 và tối đa 100.000; null khi `toTaste = true` |
| `unitId` | String hoặc null | ID đơn vị trong catalog; null khi `toTaste = true` |
| `toTaste` | Boolean | `true` nghĩa là nêm/vừa đủ, không nhập lượng và đơn vị |
| `note` | String | Ghi chú, tối đa 160 ký tự |
| `groupId` | String | Phải trỏ tới một `ingredientGroups[].id` trong cùng công thức |

Với nguyên liệu thuộc catalog, đơn vị phải có trong `unitIds` được nguyên liệu đó hỗ trợ.
Model Dart giữ `IngredientUnit`, nhưng dữ liệu ghi xuống chỉ dùng `unitId`.

**Mỗi phần tử `steps`:**

| Trường | Kiểu | Ý nghĩa |
|---|---|---|
| `id` | String | Khóa bước, không trùng trong công thức |
| `title` | String | Tên bước, tối đa 80 ký tự |
| `instruction` | String | Hướng dẫn bắt buộc, tối đa 2.000 ký tự |
| `minutes` | Integer hoặc null | 1–720 phút, null nếu không chỉ định |
| `tip` | String | Mẹo/ghi chú, tối đa 500 ký tự |
| `photo` | Map ảnh hoặc null | Ảnh của bước, xem phần 11 |

App giới hạn JSON nội dung bài gửi tối đa 400.000 byte trước khi ghi.
`rating`, `calories`, `isFavorite`, `publishedAt` không được writer bài gửi mới hiện tại tạo ra.
Trong dữ liệu mẫu/model có thể có các trường này; trạng thái yêu thích vẫn thuộc subcollection favorite.

## 7. Bản nháp — `users/{uid}/recipe_drafts/current`

Một tài khoản có một vị trí bản nháp `current`.

| Trường | Kiểu | Giá trị/ý nghĩa |
|---|---|---|
| `schemaVersion` | Integer | `1` |
| `authorId` | String | UID chủ bản nháp |
| `submissionId` | String | ID `r_...` dành sẵn cho lần gửi bài |
| `revision` | Integer | Bắt đầu `0`, tăng khi lưu; chống ghi đè nháp đã đổi trên phiên khác |
| `draft` | Map hoặc null | Nội dung đang soạn; null khi mới tạo vị trí nháp |
| `revisionOf` | String hoặc null | ID bài `rejected` đang sửa lại |
| `updatedAt` | Timestamp | Server timestamp |

`draft` có các trường:

```text
title: String
cover: Map ảnh | null
photos: List<Map ảnh> (tùy chọn, tối đa 9 ảnh bổ sung)
description: String
preparationMinutes: String
cookingMinutes: String
servings: Integer
difficulty: easy | medium | hard
storageNotes: String
meals: List<String>
categories: List<String>
ingredientGroups: List<{id, name}>
ingredients: List<{id, ingredientId, name, amount, unitId, toTaste, note, groupId}>
steps: List<{id, instruction, title, minutes, tip, photo}>
```

**Khác với bài đã gửi:** `draft.preparationMinutes`, `draft.cookingMinutes` và
`draft.steps[].minutes` là **String**, có thể là chuỗi rỗng trong lúc nhập.
`steps[].minutes` trong công thức đã gửi mới là Integer hoặc null.
Ảnh được upload trước khi lưu nháp thật; không lưu bytes/base64 vào Firestore.
Nháp không sở hữu cờ banner quản trị.

Gửi bài thành công tạo document `recipes/{submissionId}` và xóa nháp trong cùng
transaction. Khi mở lại trình soạn, app có thể tạo vị trí nháp mới.

## 8. Danh mục — `catalogs/ingredients`

Đây là một document chứa toàn bộ danh mục; không có subcollection cho từng nguyên liệu.
Nguồn quản trị: [ingredients.v1.json](data/catalogs/ingredients.v1.json).

| Trường | Kiểu | Giá trị/ý nghĩa |
|---|---|---|
| `schemaVersion` | Integer | `1` |
| `version` | String | Phiên bản dữ liệu, ví dụ `2026-11-09.v1` |
| `locale` | String | `vi-VN` |
| `categories` | List<Map> | Danh sách nhóm nguyên liệu |
| `units` | List<Map> | Danh sách đơn vị |
| `ingredients` | List<Map> | Danh sách nguyên liệu |
| `contentHash` | String | Hash nội dung do công cụ xuất bản tính |
| `updatedAt` | Timestamp | Server timestamp do công cụ xuất bản ghi |

| Phần tử | Các trường lưu |
|---|---|
| `categories[]` | `id: String`, `name: String`, `sortOrder: Integer` |
| `units[]` | `id: String`, `label: String`, `type: String`; ví dụ đơn vị `g` có `type = mass` |
| `ingredients[]` | `id: String`, `name: String`, `categoryId: String`, `aliases: List<String>`, `unitIds: List<String>`, `defaultUnitId: String` |

Ví dụ một nguyên liệu trong document:

```json
{
  "id": "beef_shank",
  "name": "Bắp bò",
  "categoryId": "meat",
  "aliases": [],
  "unitIds": ["g", "kg"],
  "defaultUnitId": "g"
}
```

`categoryId` và `defaultUnitId` phải có trong cùng phiên bản catalog;
`defaultUnitId` phải thuộc `unitIds` của nguyên liệu.
Field `group` trong model Dart được suy ra từ tên category, không phải field
cần thêm vào mỗi nguyên liệu của catalog schema 1.
Người dùng chỉ đọc document này; admin active được cập nhật qua portal, công cụ IAM
vẫn dùng để bootstrap. Portal tăng version, cập nhật contentHash/updatedAt và giữ ID đã phát hành.

## 9. Hội thoại — `conversations/{conversationId}`

ID do app tính bằng:

```text
SHA256(UTF8(jsonEncode(danh sách hai UID đã sắp xếp)))
```

Kết quả là chuỗi 64 ký tự hex, giúp app tìm lại cùng hội thoại cho một cặp tài khoản.

| Trường | Kiểu | Giá trị/ý nghĩa |
|---|---|---|
| `memberIds` | List<String> | Đúng hai UID khác nhau |
| `memberNames` | Map<String, String> | Khóa là hai UID, giá trị là snapshot tên lúc tạo hội thoại |
| `recipeId` | String | Bài đã duyệt của người nhận dùng làm căn cứ bắt đầu trò chuyện |
| `createdAt` | Timestamp | Server timestamp khi tạo |
| `updatedAt` | Timestamp | Ban đầu bằng lúc tạo, sau đó cập nhật khi có tin gửi |
| `lastMessageId` | String hoặc null | ID tin cuối; ban đầu null |
| `lastMessageText` | String | Preview tin cuối; ban đầu `""`; tin chỉ ảnh dùng `📷 Ảnh` |
| `lastSenderId` | String hoặc null | UID người gửi tin cuối; ban đầu null |
| `readAt` | Map<String, Timestamp> | Thời điểm đọc của từng thành viên; lúc tạo chỉ có UID người tạo |

Không lưu `unreadCount`, `name`, `subtitle`, `messages`, `online` hoặc `typing`
thành các field riêng trên document hội thoại. Các tên đầu là dữ liệu suy ra cho UI;
online/typing chưa được triển khai.

Hội thoại được coi là chưa đọc khi tin cuối do người khác gửi và `updatedAt` mới hơn
`readAt[uid]`, hoặc UID chưa có dấu đọc. `unreadCount` trong model hiện là **0 hoặc 1
cho hội thoại**, không phải tổng số tin chưa đọc.

Khi tạo hội thoại, Rules kiểm tra người nhận là tác giả của `recipeId` đã `approved`,
có tài khoản active và snapshot tên khớp dữ liệu hợp lệ. Thành viên không được đổi
`memberIds`/`memberNames` sau khi tạo; mỗi người chỉ cập nhật dấu đọc của mình.

## 10. Tin nhắn — `conversations/{conversationId}/messages/{messageId}`

`messageId` là request ID ngẫu nhiên 32 ký tự hex. App giữ ID này khi thử lại cùng
bản nháp để tránh tạo tin trùng sau khi đã commit nhưng mất phản hồi.

| Trường | Kiểu | Giá trị/ý nghĩa |
|---|---|---|
| `senderId` | String | UID người gửi, phải bằng UID đang xác thực |
| `text` | String | Tối đa 2.000 ký tự; được rỗng nếu có ảnh; không chấp nhận tin chỉ có khoảng trắng |
| `createdAt` | Timestamp | Server timestamp |
| `image` | Map ảnh, tùy chọn | Một ảnh cho mỗi tin; không có ảnh thì client bỏ trường này |

Không lưu `fromMe`, `timeLabel`, `status = sent/read` hoặc `isRead` trên từng tin.
`fromMe` suy ra bằng cách so sánh `senderId` với UID hiện tại; trạng thái đọc dùng
`conversations.readAt`.

Tạo tin và cập nhật preview hội thoại nằm trong cùng transaction. Rules yêu cầu
preview khớp nội dung/ảnh, không cho giả `senderId`, sửa hoặc xóa tin đã gửi.
Chỉ thành viên active được đọc lịch sử.

## 11. Dữ liệu ảnh dùng trong Firebase

Áp dụng cho `content.cover`, `content.photos[]`, `content.steps[].photo`, ảnh trong nháp đã lưu và `messages.image`.

| Trường | Kiểu | Ý nghĩa |
|---|---|---|
| `id` | String | ID ảnh phía app; với ảnh chat giới hạn tối đa 128 ký tự |
| `name` | String | Tên mô tả; ảnh chat dùng `Ảnh trò chuyện`, tối đa 120 ký tự |
| `url` | String | HTTPS thuộc `res.cloudinary.com/ddqouziau/image/upload/`, tối đa 2.048 ký tự |
| `publicId` | String | ID tài nguyên Cloudinary, 1–500 ký tự |

```json
{
  "id": "image_id",
  "name": "Ảnh trò chuyện",
  "url": "https://res.cloudinary.com/ddqouziau/image/upload/v1/example.png",
  "publicId": "example"
}
```

Đây là ví dụ cấu trúc, không khẳng định URL ví dụ có ảnh thật.
File được upload lên **Cloudinary**, không phải Firebase Storage; Firestore chỉ giữ metadata/URL.
Không ghi `bytesBase64`, bytes hoặc `assetPath` của thiết bị vào các document thật này.
Ảnh chọn trước upload giới hạn 8 MB; uploader nhận JPG/JPEG/PNG/WebP.

Quyền thành viên Firestore bảo vệ metadata và lịch sử chat, **không bảo vệ ảnh nếu
URL Cloudinary đã được chia sẻ**: người có URL có thể xem ảnh.

## 12. Dấu đã đọc thông báo — `users/{uid}/notification_reads/{notificationId}`

`notificationId` có dạng `{recipeId}_approved` hoặc `{recipeId}_rejected`.

| Trường | Kiểu | Ý nghĩa |
|---|---|---|
| `readAt` | Timestamp | Server timestamp khi đánh dấu đã đọc |

Không có collection `notifications` do client tạo trong luồng hiện tại.
Nội dung thông báo được suy ra từ bài của chính tài khoản trong `recipes` có
`status = approved/rejected`; document dấu đọc tồn tại nghĩa là thông báo đó đã đọc.
`title`, `body`, `kind`, `timeLabel`, `isRead` của `InboxNotification` là dữ liệu
được dựng trong app, không phải các field lưu trong `notification_reads`.

## 13. Lịch sử duyệt — `recipe_moderation_events/{recipeId}`

Collection do portal admin/moderator active hoặc [công cụ duyệt](tool/recipe_review_logic.cjs)
có quyền IAM ghi. Người dùng thông thường không được đọc/ghi.

| Trường | Kiểu | Ý nghĩa |
|---|---|---|
| `submissionId` | String | ID bài được duyệt, bằng ID document sự kiện |
| `authorId` | String | UID tác giả |
| `decision` | String | `approve` hoặc `reject` — khác với `status` bài là `approved`/`rejected` |
| `reviewer` | String | Portal dùng Firebase UID; CLI dùng dạng `iam:<hash định danh>` |
| `reason` | String hoặc null | Lý do; công cụ yêu cầu có khi `decision = reject` |
| `createdAt` | Timestamp | Thời điểm quyết định, server timestamp |

Portal/công cụ ghi quyết định và cập nhật bài trong cùng transaction. Rules portal
bắt buộc có cả hai thao tác trong cùng commit. Nếu sửa trạng thái
bằng Console trực tiếp thì không tự sinh document audit này; hiện không có trigger làm việc đó.

## 14. Những dữ liệu không nằm trong Firestore hiện tại

| Dữ liệu | Nơi quản lý |
|---|---|
| Email/mật khẩu/phiên đăng nhập | Firebase Authentication |
| File ảnh bìa, ảnh bước nấu, ảnh chat | Cloudinary |
| Giỏ đi chợ: tên, lượng, trạng thái tick | `_CartItem` và State trong widget; chưa có collection cart |
| Tab đang chọn, bộ lọc, tìm kiếm, bản nháp chat chưa gửi | State/Cubit trong bộ nhớ |
| Trạng thái nấu từng bước/check nguyên liệu trên màn chi tiết | State/Cubit trong bộ nhớ |
| Dữ liệu món/tác giả mẫu | `assets/mock`; không đồng nghĩa là document của tài khoản thật |
| `recipe_submissions` | Tên còn xuất hiện trong index legacy; writer hiện tại dùng `recipes`, không ghi bài mới vào collection này |

## 15. Nguồn schema

Các collection mới cho thực đơn, kho theo lô, bộ sưu tập, nhật ký, theo dõi và đánh giá
được mô tả tại [9 chức năng Góc bếp](docs/KITCHEN_FEATURES.md). Đây là thay đổi source;
trạng thái triển khai Firebase và giới hạn MVP xem trong tài liệu đó.

- [Firestore Rules](firestore.rules): quyền và kiểm tra dữ liệu tại database.
- [UserDocumentCodec](lib/features/profile/services/user_document_codec.dart): ánh xạ Timestamp và kiểm tra UID.
- [RecipeDraftCodec](lib/features/recipe_editor/services/recipe_draft_codec.dart): cấu trúc nháp.
- [FirestoreRecipeAuthoringRepository](lib/features/recipe_editor/services/firestore_recipe_authoring_repository.dart): payload bài gửi.
- [FirestoreMessageRepository](lib/features/messages/services/firestore_message_repository.dart): hội thoại/tin nhắn.
- [FirestoreNotificationRepository](lib/features/notifications/services/firestore_notification_repository.dart): nội dung thông báo và dấu đọc.
- Tài liệu chuyên sâu: [User](docs/USER_MODEL.md), [catalog](docs/INGREDIENT_CATALOG.md),
  [đăng/duyệt bài](docs/RECIPE_PUBLISHING.md), [tủ lạnh](docs/FRIDGE.md), [chat/thông báo](docs/COMMUNICATION.md).
