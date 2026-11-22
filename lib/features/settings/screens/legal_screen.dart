import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/widgets.dart';
import '../../../core/utils/app_layout.dart';

const supportEmail = 'shuichiakaik5@gmail.com';

class LegalScreen extends StatelessWidget {
  final bool privacy;
  const LegalScreen({super.key, this.privacy = false});
  @override
  Widget build(BuildContext context) {
    final sections = privacy
        ? <(String, String)>[
            (
              'Dữ liệu được xử lý',
              'Bếp Xinh xử lý thông tin tài khoản, tên hiển thị, ảnh đại diện, công thức, ảnh món ăn, đánh giá, báo cáo và tin nhắn bạn cung cấp. Dữ liệu tủ lạnh và các lựa chọn lưu món phục vụ các chức năng tương ứng.',
            ),
            (
              'Mục đích sử dụng',
              'Dữ liệu được dùng để đăng nhập, hiển thị nội dung, đồng bộ tài khoản, gửi tin nhắn và kiểm duyệt vi phạm. Hồ sơ và công thức đã duyệt có thể hiển thị cho người dùng khác; tin nhắn dành cho các thành viên cuộc trò chuyện.',
            ),
            (
              'Dịch vụ lưu trữ',
              'Ứng dụng sử dụng Firebase cho xác thực và dữ liệu, Cloudinary cho ảnh tải lên. Khi chọn ảnh hoặc camera, chỉ ảnh bạn xác nhận mới được dùng cho thao tác tương ứng. Bếp Xinh không yêu cầu bạn gửi mật khẩu qua email hoặc chat.',
            ),
            (
              'Quản lý dữ liệu',
              'Bạn có thể sửa hồ sơ, ẩn hoặc xóa bài của mình theo các thao tác trong ứng dụng. Để yêu cầu truy cập, chỉnh sửa hoặc xóa dữ liệu tài khoản, liên hệ $supportEmail; quản trị viên sẽ xác minh quyền sở hữu trước khi xử lý.',
            ),
            (
              'Trợ lý AI',
              'Khi dùng Bếp Xinh AI, nội dung hội thoại AI và một số công thức công khai phù hợp được gửi đến nhà cung cấp AI do quản trị viên cấu hình để tạo câu trả lời. Hội thoại AI lưu theo tài khoản. Ứng dụng không tự gửi chat với người dùng khác hoặc dữ liệu tủ lạnh riêng sang AI. Không nhập mật khẩu, mã xác minh hoặc thông tin nhạy cảm vào cuộc trò chuyện này.',
            ),
            (
              'Liên hệ',
              'Gửi câu hỏi về dữ liệu hoặc yêu cầu hỗ trợ tới $supportEmail. Không gửi mật khẩu hoặc mã xác minh trong thư.',
            ),
          ]
        : <(String, String)>[
            (
              'Sử dụng Bếp Xinh',
              'Bếp Xinh hỗ trợ chia sẻ công thức và quản lý việc nấu ăn. Bạn chịu trách nhiệm bảo vệ tài khoản và tính chính xác của nội dung do mình cung cấp.',
            ),
            (
              'Nội dung cộng đồng',
              'Chỉ đăng nội dung bạn có quyền sử dụng. Không đăng nội dung xúc phạm, giả mạo, spam, quảng cáo lừa đảo hoặc hướng dẫn gây nguy hiểm. Công thức và đánh giá có thể cần được duyệt trước khi công khai.',
            ),
            (
              'An toàn khi nấu ăn',
              'Kiểm tra nguyên liệu, dị ứng và độ chín phù hợp trước khi dùng. Thời gian và khẩu phần trong công thức chỉ là gợi ý; bạn cần điều chỉnh theo thiết bị và điều kiện thực tế.',
            ),
            (
              'Kiểm duyệt và đình chỉ',
              'Quản trị viên có thể ẩn nội dung hoặc đình chỉ tài khoản vi phạm. Nếu muốn đề nghị xem xét hoặc mở khóa, liên hệ $supportEmail và cung cấp thông tin tài khoản cần hỗ trợ.',
            ),
            (
              'Nội dung biến tấu',
              'Khi đăng bản biến tấu, ghi rõ nguồn và thay đổi. Việc dẫn nguồn không thay thế nghĩa vụ có quyền sử dụng nội dung của người khác.',
            ),
          ];
    return AppPageScaffold(
      appBar: AppSliverAppBar(
        title: privacy ? 'Chính sách bảo mật' : 'Điều khoản dịch vụ',
        onBackPressed: () =>
            context.canPop() ? context.pop() : context.go('/login'),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: AppLayout.formWidth(context)),
          child: AppContentScrollView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text('Cập nhật ngày 17/11/2026'),
              for (final section in sections) ...[
                const SizedBox(height: 24),
                Text(
                  section.$1,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(section.$2),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
