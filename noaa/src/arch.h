// basic libarchive defs.

/* Declare our basic types. */
struct archive;
struct archive_entry;

// funcs
struct archive *archive_read_new(void);
int archive_read_support_filter_all(struct archive *);
int archive_read_support_format_tar(struct archive *);
struct archive_entry* archive_entry_new();
int archive_entry_free(struct archive_entry*);
int archive_read_close(struct archive*);
int archive_read_free(struct archive*);
int archive_read_open_filename(struct archive*, const char*, int);
int archive_read_next_header(struct archive*, struct archive_entry**);
char* archive_entry_pathname(struct archive_entry*);
int archive_entry_size(struct archive_entry*);
int archive_entry_filetype(struct archive_entry*);
int archive_entry_clear(struct archive_entry*);
int archive_read_data(struct archive*, char*, int);
char* archive_error_string(struct archive*);