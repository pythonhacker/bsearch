## About

This is `bsearch` - which stands for `Basic Search`, a simple search engine purely using console tools
and written in bash script.

## Requirements

1. `bash` - version 4.0 and up
2. `findutils` - for the `find` command
3. `poppler-utils` OR `libimage-exiftool-perl` - for the `pdfinfo` or `exiftool`
   commands, for indexing metadata of PDF files.

Install dependecies using your native package manager.
For systems using `apt`

	$ sudo apt install findutils poppler-utils libimage-exiftool-perl -y

## Running

The tool has two modes - Indexing and Searching.

Indexing is the default mode and can be invoked with the `-r` and `-t` parameters, which stands for the
root folder and filetype respectively. By default all files are indexed.

The filetype if given should be the extension of the required file without the "." prefix - for example "pdf" for PDFs.
It also accepts mimetypes - for example `image/jpeg` for all JPEG/JFIF images.

When indexing, it gives a running count of the files.

### Indexing 

	$ ./bsearch -t pdf -r ~
	Running in indexing mode - invoked on /home/anand with filetype pdf
	Building list of files...
	Processed #1209 files.
	Creating indices...
	Indexed #1209 files...
	Created 1209 hash index entries.
	Created 11477 path index entries.
	Created 11313 meta index entries.
	Created 23999 total index entries.

	$ ./bsearch -r ~/Documents/
	Running in indexing mode - Invoked on /home/anand/Documents/
	Building list of files...
	Processed #177 files.
	Creating indices...
	Indexed #177 files...
	Created 177 hash index entries.
	Created 1051 path index entries.
	Created 1023 meta index entries.
	Created 2251 total index entries.

	$ ./bsearch -t image/jpeg -r ~/Pictures
	Running in indexing mode - invoked on /home/anand/Pictures with filetype image/jpeg
	Mimetype given, fetching extensions for image/jpeg
	Building list of files...
	Processed #5730 files.
	Creating indices...
	Indexed #5730 files...
	Created 5730 hash index entries.
	Created 42441 path index entries.
	Created 0 meta index entries.
	Created 48171 total index entries.

Note that the indexing is done only for file metadata — such as paths and file extension and document
level metadata for PDFs. No actual content is ingested.

Hidden folders and files are always skipped.

### Searching 

To search run the tool using `-s` flag and supplying a single search param.
The search results are the file paths that match. There is no ranking.

Examples:

	$ ./bsearch -s matterhorn
	Running in search mode with query "matterhorn"

	/home/anand/Documents/Matterhorn-Protocol-1-1.txt
	/home/anand/Documents/Matterhorn-Protocol-1-1.pdf

	Found 2 hits for query "matterhorn".

	$ ./bsearch -s python
	Running in search mode with query "python"
	
	/home/anand/programs/python/rfc3917.pdf
	/home/anand/programs/python/text2pdf.pdf
	/home/anand/programs/python/rfc3164.pdf

	Found 3 hits for query "python".
	
For metadata search, give the query in "<field>:<value>" format. For example "producer:word" or "title:untitled".

	$ ./bsearch -s "producer:word"
	/home/anand/Documents/joint_declaration.pdf
	/home/anand/Documents/Architect.pdf
	/home/anand/Documents/WordSample.pdf	

Currently we index metadata of only PDF files so such queries make sense only for PDFs.

## Storage

The indices are created and stored in the folder `~/.local/state/bsearch.db`.
It uses a simple inverted index that uses folders and files as keys and contents as value.

## Performance

When not indexing metadata, at the rate of about 60 files/second.
When indexing PDF metadata, at the rate of about 17 files/second.

Benchmark were done on a Lenovo laptop with 16 core CPU/24GB RAM on a linux ext4 filesystem.

## Unit Tests
A unit test file is available, run it using:

	$ ./test_bsearch.sh ./bsearch
	
