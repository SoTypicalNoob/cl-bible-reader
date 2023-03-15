(ql:quickload :sxql)
(ql:quickload :dbi)
(ql:quickload :str)
(ql:quickload "cl-ppcre")

(defun book-mapper (database book-name)
  (second (first (dbi:fetch-all
                  (dbi:execute
                   (dbi:prepare database "SELECT book_number FROM books WHERE long_name = ?") (list book-name))))))

(defun cleared-verse (raw-verse)
  (ppcre:regex-replace-all "<pb\/>" (ppcre:regex-replace-all "<f>.*?<\/f>" raw-verse "") ""))

(defun fetch-verse (database verse)
  (cleared-verse (second (first (dbi:fetch-all
                                 (dbi:execute
                                  (dbi:prepare database "SELECT text FROM verses WHERE book_number = ? AND chapter = ? AND verse = ?")
                                  verse))))))

(defun list-of-books (connection)
  (loop :for book :in (dbi:fetch-all
                           (dbi:execute
                            (dbi:prepare connection "SELECT long_name FROM books")))
        :collect (second book)))

(defun fuzzy-book-search (seeking books)
  (loop :for book :in books
        :when (cl-ppcre:scan seeking book)
        :collect book))

(defun bible-reader (database bible-ref)
  (let* ((connection (dbi:connect :sqlite3 :database-name database))
         (list-of-books (list-of-books connection))
         (book-id (book-mapper connection (first (fuzzy-book-search (first bible-ref) list-of-books))))
         )
    (format t "~{~A, ~}" list-of-books)
    (fetch-verse connection (list book-id (second bible-ref) (third bible-ref)))))
