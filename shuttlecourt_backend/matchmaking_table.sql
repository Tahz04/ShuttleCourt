CREATE TABLE IF NOT EXISTS `matchmaking` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `host_id` int(11) NOT NULL,
  `court_name` varchar(255) NOT NULL,
  `level` varchar(50) NOT NULL,
  `match_date` date NOT NULL,
  `start_time` time NOT NULL,
  `capacity` int(11) NOT NULL,
  `joined_count` int(11) NOT NULL DEFAULT 1,
  `price` decimal(10,2) NOT NULL,
  `description` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  CONSTRAINT `matchmaking_ibfk_1` FOREIGN KEY (`host_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
