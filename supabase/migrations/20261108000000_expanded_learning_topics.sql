-- Add metadata only. Local practice remains separate from verified server content.
-- Preserve all existing metadata, RLS and publication state on replay.
INSERT INTO public.topics(id,title,subtitle,subject,action_label,icon_key,sort_order,status) VALUES
  ('english','Tiếng Anh trong cuộc sống','Nghe, ghép câu và luyện nói từ lời chào đến yêu cầu lịch sự.','Ngôn ngữ','Nghe và nói một câu mới','record_voice_over_outlined',13,'draft'),
  ('vietnamese','Tiếng Việt & giao tiếp','Kể chuyện, nối ý, viết rõ ràng và lập luận bằng bằng chứng.','Ngôn ngữ','Biến ý tưởng thành lời','chat_bubble_outline',14,'draft'),
  ('biology','Sự sống quanh ta','Từ bộ phận cây đến hệ sinh thái và thiết kế thí nghiệm.','Sinh học','Khám phá một hệ sống','eco_outlined',15,'draft'),
  ('chemistry','Vật chất & biến đổi','Phân loại vật chất, đếm nguyên tử và kiểm tra giả thuyết.','Hóa học','Thử trong phòng lab số','science_outlined',16,'draft'),
  ('astronomy','Bầu trời & vũ trụ','Khám phá ngày đêm, pha Mặt Trăng và lập kế hoạch thám hiểm.','Thiên văn','Theo dấu một thiên thể','nightlight_round',17,'draft'),
  ('finance','Tiền & lựa chọn','Từ nhu cầu, tiết kiệm đến phân bổ nguồn lực và đọc lời hứa.','Kỹ năng sống','Lập ngân sách bằng mô hình','savings_outlined',18,'draft'),
  ('digital','Công dân số thông minh','Bảo vệ thông tin, kiểm chứng tin và dùng AI có trách nhiệm.','Kỹ năng số','Điều tra một thông tin','verified_user_outlined',19,'draft')
ON CONFLICT(id) DO NOTHING;
