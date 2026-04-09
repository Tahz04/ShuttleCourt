-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Máy chủ: 127.0.0.1
-- Thời gian đã tạo: Th4 09, 2026 lúc 09:45 AM
-- Phiên bản máy phục vụ: 10.4.32-MariaDB
-- Phiên bản PHP: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Cơ sở dữ liệu: `quynh_db`
--

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `courts`
--

CREATE TABLE `courts` (
  `id` int(11) NOT NULL,
  `owner_id` int(11) NOT NULL,
  `name` varchar(255) NOT NULL,
  `address` text NOT NULL,
  `latitude` decimal(10,8) DEFAULT NULL,
  `longitude` decimal(11,8) DEFAULT NULL,
  `price_per_hour` decimal(10,2) NOT NULL,
  `description` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Đang đổ dữ liệu cho bảng `courts`
--

INSERT INTO `courts` (`id`, `owner_id`, `name`, `address`, `latitude`, `longitude`, `price_per_hour`, `description`, `created_at`) VALUES
(1, 4, 'Sân Cổng Chào ', 'Sân Cổng Mĩ Đình', 21.02040000, 105.77390000, 120000.00, '', '2026-04-08 01:24:55'),
(2, 4, 'Sân Vincom', 'Sân vincom', 20.02040000, 105.77090000, 90000.00, '', '2026-04-08 01:40:38');

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `users`
--

CREATE TABLE `users` (
  `id` int(11) NOT NULL,
  `full_name` varchar(100) NOT NULL,
  `email` varchar(100) NOT NULL,
  `phone` varchar(20) NOT NULL,
  `password` varchar(255) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `role` varchar(20) NOT NULL DEFAULT 'user'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Đang đổ dữ liệu cho bảng `users`
--

INSERT INTO `users` (`id`, `full_name`, `email`, `phone`, `password`, `created_at`, `role`) VALUES
(1, 'Nguyen Van A', 'test@example.com', '0123456789', '$2b$10$sY3uF3Ownxbcy6JAa3tw7.hq5j6VGVkGZHTbuDOXZfc6tQhDoluju', '2026-03-29 09:11:31', 'user'),
(2, 'quỳnh', 'quynh@gmail.com', '234567', '$2b$10$q97e4JaYoyrKeqpib8aU6.YG8F/aUehBBSmuODajzCAUUc9Xj5ycm', '2026-04-01 23:06:01', 'user'),
(3, 'Chủ Sân Test', 'chusan@gmail.com', '0999888777', '$2b$10$q97e4JaYoyrKeqpib8aU6.YG8F/aUehBBSmuODajzCA...', '2026-04-07 08:00:00', 'owner'),
(4, 'Nguyễn Văn Duy', 'vanduy3824@gmail.com', '0986049032', '$2b$10$px6QYA4iKO09y9tQFnvvv.V/giMSgMnWV73n2bUxgNNlomsr/o1Wa', '2026-04-07 08:06:19', 'owner');

--
-- Chỉ mục cho các bảng đã đổ
--

--
-- Chỉ mục cho bảng `courts`
--
ALTER TABLE `courts`
  ADD PRIMARY KEY (`id`),
  ADD KEY `owner_id` (`owner_id`);

--
-- Chỉ mục cho bảng `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `email` (`email`);

--
-- AUTO_INCREMENT cho các bảng đã đổ
--

--
-- AUTO_INCREMENT cho bảng `courts`
--
ALTER TABLE `courts`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT cho bảng `users`
--
ALTER TABLE `users`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- Các ràng buộc cho các bảng đã đổ
--

--
-- Các ràng buộc cho bảng `courts`
--
ALTER TABLE `courts`
  ADD CONSTRAINT `courts_ibfk_1` FOREIGN KEY (`owner_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
