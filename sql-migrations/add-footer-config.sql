
UPDATE public.content
SET content = '{"order":10,"label":"Data.gov.au"}'
WHERE id = 'footer/navigation/small/category/magda2';

INSERT INTO public.content VALUES ('footer/navigation/small/category-links/magda2/signin', 'application/json', '{"order":30,"label":"Sign in","href":"https://data.gov.au/user/login"}');
INSERT INTO public.content VALUES ('footer/navigation/small/category-links/magda2/feedback', 'application/json', '{"order":40,"label":"Give feedback","href":"feedback"}');

UPDATE public.content
SET content = '{"order":10,"label":"Data.gov.au"}'
WHERE id = 'footer/navigation/medium/category/magda';
INSERT INTO public.content VALUES ('footer/navigation/medium/category-links/magda/feedback', 'application/json', '{"order":40,"label":"Give feedback","href":"feedback"}');

INSERT INTO public.content VALUES ('footer/navigation/medium/category/publishers', 'application/json', '{"order":15,"label":"Publishers"}');
INSERT INTO public.content VALUES ('footer/navigation/medium/category-links/publishers/signin', 'application/json', '{"order":10,"label":"Sign in","href":"https://data.gov.au/user/login"}');
INSERT INTO public.content VALUES ('footer/navigation/medium/category-links/publishers/toolkit', 'application/json', '{"order":20,"label":"Open data toolkit","href":"https://toolkit.data.gov.au/"}');


INSERT INTO public.content VALUES ('footer/navigation/medium/category-links/magda/suggest', 'application/json', '{"order":20,"label":"Suggest a dataset","href":"suggest"}');
INSERT INTO public.content VALUES ('footer/navigation/medium/category-links/magda/privacy', 'application/json', '{"order":30,"label":"Privacy Policy","href":"page/privacy-policy"}');


INSERT INTO public.content VALUES ('footer/copyright/dta', 'application/json', '{"order":20,"href":"https://dta.gov.au/","logoSrc":"data:image/png;base64,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","logoClassName":"dta-logo","logoAlt":"DTA Logo","htmlContent":"Operated with&nbsp;<span role=\"img\" aria-label=\"love\">❤️</span>&nbsp;by&nbsp;"}');