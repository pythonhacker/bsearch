## About

This is `bsearch` - which stands for `Basic Search`, a simple search engine purely using console tools
and written in bash script.

## Requirements

1. `bash` - version 4.0 and up
2. `findutils` - for the `find` command
3. `poppler-utils` - for `pdfinfo`, to index metadata of PDF files.
4. `libimage-exiftool-perl` - for `exiftool`, to index metadata of Images.

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
	[2026-10-21 14:04:48] Running in indexing mode - invoked on "/home/anand" with filetype pdf
	[2026-10-21 14:04:48] Building list of files...
	[2026-10-21 14:04:59] Processed #1210 files.
	[2026-10-21 14:04:59] Creating indices...
	[2026-10-21 14:06:06] Indexed #1210 files...
	[2026-10-21 14:06:06] Created 1210 hash index entries.
	[2026-10-21 14:06:06] Created 11484 path index entries.
	[2026-10-21 14:06:06] Created 5624 meta index entries.
	[2026-10-21 14:06:06] Created 18318 total index entries.

	$ ./bsearch -r ~/Documents/
	[2026-10-21 16:09:07] Running in indexing mode - Invoked on "/home/anand/Documents/"
	[2026-10-21 16:09:07] Building list of files...
	[2026-10-21 16:09:07] Processed #180 files.
	[2026-10-21 16:09:07] Creating indices...
	[2026-10-21 16:09:13] Indexed #180 files...
	[2026-10-21 16:09:13] Created 88 hash index entries.
	[2026-10-21 16:09:13] Created 498 path index entries.
	[2026-10-21 16:09:13] Created 29 meta index entries.
	[2026-10-21 16:09:13] Created 615 total index entries.

	$ ./bsearch -r ~/Pictures/ -t image/jpeg                                                                      [2026-10-21 16:09:50] Running in indexing mode - invoked on "/home/anand/Pictures/" with filetype image/jpeg
	[2026-10-21 16:09:50] Mimetype given, fetching extensions for image/jpeg
	[2026-10-21 16:09:50] Building list of files...
	[2026-10-21 16:09:55] Processed #5485 files.
	[2026-10-21 16:09:55] Creating indices...
	[2026-10-21 16:25:14] Indexed #5485 files...
	[2026-10-21 16:25:14] Created 5485 hash index entries.
	[2026-10-21 16:25:14] Created 41068 path index entries.
	[2026-10-21 16:25:14] Created 23898 meta index entries.
	[2026-10-21 16:25:14] Created 70451 total index entries.

Note that the indexing is done only for file metadata — such as paths and file extension and document
level metadata for PDF documents and Images. No actual content is ingested.

Hidden folders and files are always skipped.

### Searching 

To search run the tool using `-s` flag and supplying a single search param.
The search results are the file paths that match. There is no ranking.

Examples:

	$ ./bsearch -s matterhorn
	[2026-10-21 18:02:20] Running in search mode with query "matterhorn"

	/home/anand/Documents/pdfAccess/Matterhorn-Protocol-1-1.txt
	/home/anand/Documents/pdfAccess/Matterhorn-Protocol-1-1.pdf

	[2026-10-21 18:02:21] Found 2 hits for query "matterhorn".

	$ ./bsearch -s python
	[2026-10-21 18:02:47] Running in search mode with query "python"
	
	/home/anand/programs/python/rfc3917.pdf
	/home/anand/programs/python/text2pdf.pdf
	/home/anand/programs/python/rfc3164.pdf

	[2026-10-21 18:02:48] Found 3 hits for query "python".
	
For metadata search, give the query in "&lt;field&gt;:&lt;value&gt;" format. For example "producer:word" or "title:untitled".

	$ ./bsearch -s "producer:word"
	[2026-10-21 18:04:34] Performing meta search using key=producer and value=word
	
	/home/anand/Documents/joint_declaration.pdf
	/home/anand/Documents/Architect.pdf
	/home/anand/Documents/WordSample.pdf

	[2026-10-21 18:04:34] Found 3 hits for query "producer:word".

	$ ./bsearch -s camera:iphone
	[2026-10-21 18:18:07] Running in search mode with query "camera:iphone"
	[2026-10-21 18:18:07] Performing meta search using key=camera and value=iphone

	/home/anand/Pictures/PHOTOSTICKBACKUP/img_1529.jpg

	[2026-10-21 18:18:07] Found 1 hits for query "camera:iphone".

Note that for meta search strings with spaces doesn't work so if you want to search for a value containing spaces, split it into its sub-strings and search for any. E.g: `source:digital` for `digital camera`. Also multiple keyword search is not supported right now. 

Currently we index metadata of PDFs and Images, so these queries make sense only for these documents.


### Piping Output

To do some post-processing on listed images, one may want to pipe the output of search to another application.
For example to open images in a viewer (`eog` in this case),

	$ ./bsearch -s camera:canon 2>/dev/null | xargs eog

This works because bsearch writes all logs to `stderr` and only result filenames to `stdout`.

## Metadata Keys

The following are the metadata keys available for search.

| Metadata Key | What it stands for | Document Type | Example |
|---|---|---|---|
| `creator` | Software which originally created the source of the PDF document | PDF | `word` |
| `producer` | Software which originally exported the original document to PDF | PDF | `libreoffice` |
| `version` | Version of the document | PDF | `1.7` |
| `title` | Title of the document | PDF | `untitled` |
| `encrypted` | Is the PDF document encrypted? (yes or no) | PDF | `yes` |
| `tagged` | Is the PDF document tagged? (yes or no) | PDF | `yes` |
| `make` | Make of the camera or device | Image | `nikon` |
| `camera` | Actual model name of the camera or device | Image | `d5300` |
| `resolution` | Resolution of the image | Image | `6000x4000` |
| `orientation` | Orientation of the image | Image | `horizontal`, `rotate 90 cw` |
| `software` | Software that processed the image | Image | `picasa`, `gimp` |
| `source` | Type of the source of image | Image | `digital camera` |

In addition, when photos have proper GPS tags, `exiftool` extracts and indexes them,
so the following additional keywords become available, here listed in decreasing
relative geographic size.

| Metadata Key | What it stands for | Document Type | Example |
|---|---|---|---|
| `country` | Country where the image was taken | Image | `india`
| `region` | Region  where the image was taken | Image | `karnataka`
| `city` | City where the image was taken | Image | `bengaluru`
| `subregion` | Sub-region in the city where the image was taken | Image | `bengaluru urban`


## Listing Metadata

The following command line options allow to list metadata.

To list all available metadata keys, use `-m` flag. This list currently available
unique metadata keys in the index.

	$ ./bsearch -m
	[2026-10-21 18:10:10] 16 unique meta keys found in the index.

	1. camera
	2. city
	3. country
	4. creator
	5. encrypted
	6. make
	7. orientation
	8. pdf version
	9. producer
	10. region
	11. resolution
	12. software
	13. source
	14. subregion
	15. tagged
	16. title

To list unique values in the index for a given key, use `-l`.

For example to list the unique camera data ingested via Images.

	$./bsearch -l camera
	[2026-10-21 18:15:38] Found 15 unique keys for 'camera'
                                                                                                              
	1. 6300
	2. a142
	3. asus_z012db
	4. canon digital ixus 40
	5. canon eos 5d mark ii
	6. canon eos 700d
	7. canon powershot elph 100 hs
	8. canon powershot s410
	9. coolpix p520
	10. cymera
	11. dmc-s3
	12. dsc-t70
	13. e63
	14. e65
	15. iphone 5

The indices are created and stored in the folder `~/.local/state/bsearch.db`.
It uses a simple inverted index that uses folders and files as keys and contents as value.

## Performance

When not indexing metadata, at the rate of about 60 files/second.
When indexing PDF metadata, at the rate of about 17 files/second.

Benchmark were done on a Lenovo laptop with 16 core CPU/24GB RAM on a linux ext4 filesystem.

## Unit Tests
A unit test file is available, run it using:

	$ ./test_bsearch.sh ./bsearch
	
## TODO

In order of decreasing priority:-

| Issue | Notes | Type |
|---|---|---|
| Implement multiple keyword search | Very useful | Search |
| Try parallel indexing using `parallel` or `xargs` | Indexing is slow for Images with GPS information | Indexing |
