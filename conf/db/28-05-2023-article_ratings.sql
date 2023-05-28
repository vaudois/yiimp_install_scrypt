CREATE TABLE article_ratings (
  id INT AUTO_INCREMENT PRIMARY KEY,
  article_id INT NOT NULL,
  rating INT NOT NULL,
  user_id INT NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (article_id) REFERENCES articles(id),
  FOREIGN KEY (user_id) REFERENCES accounts(id)
);
