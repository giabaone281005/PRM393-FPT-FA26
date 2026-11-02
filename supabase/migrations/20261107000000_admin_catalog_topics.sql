-- Metadata for the two topics already bundled in mobile; no lesson publication.
-- Existing topic metadata is never overwritten.
INSERT INTO public.topics(id,title,subtitle,subject,action_label,icon_key,sort_order,status) VALUES
  ('marxism','Chủ nghĩa Mác–Lênin','Tìm hiểu khái niệm, phân tích tình huống và đọc nguồn có đối chiếu.','Triết học & xã hội','Đọc, phân tích và đối chiếu','menu_book_outlined',11,'draft'),
  ('painting','Hội họa & ngôn ngữ thị giác','Từ sắc độ, hình khối đến chiều sâu và phân tích bố cục.','Nghệ thuật','Quan sát để hiểu một bức tranh','palette_outlined',12,'draft')
ON CONFLICT(id) DO NOTHING;
