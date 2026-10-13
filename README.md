# MathLingo 🦉 - Ứng Dụng Học Toán Tương Tác Cho Trẻ Em (PRM393)

> **Mobile Application**: Flutter (Android/iOS)  
> **Backend & Database**: Supabase (PostgreSQL, Auth, Storage, RLS)  
> **Dự án nhóm**: PRM393 - FPT University  

---

## 🚀 1. Hướng Dẫn Khởi Chạy Cho Thành Viên Mới (Onboarding)

### Bước 1: Yêu cầu môi trường
* **Flutter SDK**: Phiên bản stable (khuyến nghị Flutter 3.24+ trở lên)
* **Dart SDK**: Đi kèm với Flutter
* **Android Studio / VS Code** đã cài Flutter Extension
* Thiết bị Android thật (bật Developer Options) hoặc Android Emulator

### Bước 2: Clone dự án và cài thư viện
```bash
# Clone repo về máy
git clone https://github.com/giabaone281005/PRM393-FPT-FA26.git
cd PRM393-FPT-FA26

# Chuyển sang nhánh develop để làm việc
git checkout develop

# Cài đặt các dependencies
flutter pub get

# Kiểm tra môi trường
flutter doctor
```

### Bước 3: Chạy ứng dụng
```bash
flutter run
```

---

## ⚡ 2. Cấu Hình Supabase Cho Cả Nhóm

### Cách hoạt động:
* Thông tin kết nối Supabase nằm tại file `lib/core/supabase/supabase_service.dart`.
* Cả nhóm sẽ dùng **chung 1 project Supabase** trên Cloud.
* Team Lead (hoặc người tạo project) sẽ mời các thành viên còn lại vào project tại:  
  **Supabase Dashboard > Settings > Members > Invite**.

### Khởi tạo Database (Nếu tạo mới Project Supabase):
Nếu cần khởi tạo Database hoặc reset dữ liệu, vào **Supabase Dashboard > SQL Editor** và chạy lần lượt 2 file:
1. `supabase/migrations/20261013000000_mathlingo_init.sql` (Tạo bảng, RLS Policies, Triggers)
2. `supabase/seed.sql` (Nạp dữ liệu mẫu: Bài học, câu hỏi, linh vật, vật phẩm)

---

## 🌿 3. Quy Ước Làm Việc Với Git (Git Workflow)

```text
main (Bản nộp bài / demo ổn định)
  └── develop (Nhánh tích hợp chung của cả nhóm)
        ├── feat/auth-kid-profile (Thành viên 1)
        ├── feat/learning-path (Thành viên 2)
        ├── feat/arena-battle (Thành viên 3)
        └── feat/parent-wardrobe (Thành viên 4)
```

### Quy tắc bất di bất dịch:
1. **Không bao giờ push trực tiếp lên nhánh `main` và `develop`**.
2. **Luôn tạo nhánh mới từ `develop`**:
   ```bash
   git checkout develop
   git pull origin develop
   git checkout -b feat/ten-tinh-nang
   ```
3. **Trước khi push nhánh của mình lên GitHub**:
   ```bash
   # Cập nhật code mới nhất từ develop về nhánh tính năng
   git checkout develop
   git pull origin develop
   git checkout feat/ten-tinh-nang
   git merge develop
   
   # Test lại app đảm bảo không lỗi
   flutter run
   
   # Đẩy nhánh lên GitHub và tạo Pull Request
   git push origin feat/ten-tinh-nang
   ```
4. **Tạo Pull Request (PR)** trên GitHub vào nhánh `develop`, gửi link vào nhóm để ít nhất 1 bạn khác review trước khi merge.

---

## 📁 4. Cấu Trúc Thư Mục (Feature-First Architecture)

```text
lib/
├── core/                  # Theme, colors, typography, supabase config dùng chung
│   ├── supabase/          # SupabaseService (Auth, Client, DB helper)
│   └── theme/             # AppTheme, Colors, Typography
├── data/                  # Models, Repositories, Providers (ChangeNotifier)
│   ├── models/            # KidProfile, Lesson, Question...
│   ├── repositories/      # Auth, Kid, Arena, Mascot Repositories
│   └── providers/         # AppStateProvider (Quản lý trạng thái toàn app)
└── features/              # Chia theo từng màn hình / phân hệ tính năng
    ├── ai_scanner/        # Giải bài toán bằng camera AI
    ├── arena/             # Đấu trường thi đấu toán học & BXH
    ├── auth/              # Đăng ký / Đăng nhập phụ huynh
    ├── home/              # Màn hình chính
    ├── kid_profile/       # Quản lý hồ sơ trẻ em & chuyển hồ sơ
    ├── learning_engine/   # Engine học tập tương tác (kéo thả, đồng hồ, vẽ lưới)
    ├── mascot_wardrobe/   # Tủ đồ linh vật cú Mathy
    ├── parent_portal/     # Cổng phụ huynh (Cài đặt PIN, giới hạn giờ chơi)
    ├── practice_garden/   # Vườn luyện tập hồi tim
    └── reward/            # Phần thưởng & rương kho báu
```
