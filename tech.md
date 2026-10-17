sử dụng ontap quản lý tập trung

# dùng cho widget button

AppButton(
  text: 'Đăng nhập',
  actionName: 'btn_login',
  requiresNetwork: true, // Tự động chặn và báo SnackBar nếu mất mạng
  throttleDuration: Duration(milliseconds: 600), // Chống click liên tục
  onPressed: () {
    // Logic thực hiện bình thường
  },
)
# Cho Card, Item, Banner, Icon

AppTap(
  actionName: 'recipe_item_click',
  requiresNetwork: true,
  scaleOnTap: true, // Hiệu ứng co nhẹ khi chạm
  onTap: () {
    // Chuyển màn hình chi tiết món ăn
  },
  child: RecipeCard(recipe: item),
)
# Dùng Extension context.onAppTap

IconButton(
  icon: const Icon(Icons.share),
  onPressed: context.onAppTap(
    () => shareRecipe(),
    actionName: 'share_recipe',
    requiresNetwork: true,
  ),
)
