-- Add page_count column to books table for stacking feature
ALTER TABLE public.books 
ADD COLUMN page_count INTEGER DEFAULT 0;

-- Optional: Update existing records if needed (though default handles new ones)
-- UPDATE public.books SET page_count = 0 WHERE page_count IS NULL;
