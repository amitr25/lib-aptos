module Library::Library {
    use std::signer;
    use std::string;
    use aptos_std::table_with_length;
    use aptos_std::table_with_length::{TableWithLength};

    //
    // Error codes
    //
    const EBOOK_NOT_FOUND: u64 = 1001;
    const EBOOK_ALREADY_BORROWED: u64 = 1002;
    const EBOOK_NOT_BORROWED: u64 = 1003;

    //
    // Book structure
    //
    struct Book has copy, drop, store {
        title: string::String,
        author: string::String,
        is_borrowed: bool,
    }

    //
    // Library resource
    //
    struct Library has key {
        books: TableWithLength<u64, Book>,
        next_id: u64,
    }

    //
    // Initialize Library (only once by admin)
    //
    public entry fun init_library(account: &signer) {
        move_to(account, Library {
            books: table_with_length::new<u64, Book>(),
            next_id: 0,
        });
    }

    //
    // Add a book
    //
    public entry fun add_book(account: &signer, title: string::String, author: string::String) acquires Library {
        let library = borrow_global_mut<Library>(signer::address_of(account));
        let id = library.next_id;
        library.next_id = id + 1;

        let book = Book { title, author, is_borrowed: false };
        table_with_length::add(&mut library.books, id, book);
    }

    //
    // Borrow a book
    //
    public entry fun borrow_book(account: &signer, book_id: u64) acquires Library {
        let library = borrow_global_mut<Library>(signer::address_of(account));

        if (!table_with_length::contains(&library.books, book_id)) {
            abort EBOOK_NOT_FOUND;
        };

        let book_ref = table_with_length::borrow_mut(&mut library.books, book_id);
        if (book_ref.is_borrowed) {
            abort EBOOK_ALREADY_BORROWED;
        };

        book_ref.is_borrowed = true;
    }

    //
    // Return a book
    //
    public entry fun return_book(account: &signer, book_id: u64) acquires Library {
        let library = borrow_global_mut<Library>(signer::address_of(account));

        if (!table_with_length::contains(&library.books, book_id)) {
            abort EBOOK_NOT_FOUND;
        };

        let book_ref = table_with_length::borrow_mut(&mut library.books, book_id);
        if (!book_ref.is_borrowed) {
            abort EBOOK_NOT_BORROWED;
        };

        book_ref.is_borrowed = false;
    }
}

