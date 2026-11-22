# Messages

`screens` cấp Cubit và điều hướng; `widgets` trình bày inbox/composer/bubble.
`cubits` sở hữu query, bản nháp và trạng thái gửi; `services` sở hữu query,
transaction và xác minh phiên Firebase. Không gọi Firestore trong widget.
Contract quyền thành viên, retry, giới hạn lịch sử và kiểm thử:
[COMMUNICATION.md](../../../docs/COMMUNICATION.md).

ChatRecipe / ChatRecipesCubit / ChatRecipeCard bổ sung chọn và gửi món công khai. Contract: [CHAT_RECIPES.md](../../../docs/CHAT_RECIPES.md).
