-- ДЗ №1. Кредитные рейтинги
-- Пункт 1. Создадим новую пустую таблицу: ratings_tasks, зададим форматы столбцов. Далее подготовим данные из файлов excel для импортирования в таблицу, изменив формат столбцов в датами на (general>>date). Другие данные не изменяем. Первичный ключ не создаем, тк значения могут повторяться.
-- Создадим таблицу:

Drop table if exists public.ratings;

CREATE TABLE public.ratings
(
"rat_id smallint NOT NULL,
"rat_grade" text COLLATE pg_catalog."default" NOT NULL,
"outlook" text COLLATE pg_catalog."default",
"rate_change" text COLLATE pg_catalog."default" NOT NULL,
"date" date,
"finst" bigint,
"agency_id" text COLLATE pg_catalog."default",
"industry" text COLLATE pg_catalog."default",
"rat_type" text COLLATE pg_catalog."default",
"horizon" text COLLATE pg_catalog."default",
"scale_typer" text COLLATE pg_catalog."default",
"currency" text COLLATE pg_catalog."default",
"backed_flag" text COLLATE pg_catalog."default"
"rat_name" text COLLATE pg_catalog."default”,
"OKPO" bigint NOT NULL,
"ORGN" bigint,
"INN" bigint,

)

TABLESPACE pg_default;

-- Добавим первичный ключ:

CONSTRAINT ratings_pkey PRIMARY KEY ("rat_id")

-- Назначим владельца таблицы:

ALTER TABLE public.ratings
OWNER to postgres;

-- Аналогично создадим таблицу credit_events.

DROP TABLE IF EXISTS public.credit_events;

CREATE TABLE public.credit_events
(
"inn" bigint NOT NULL,
"date" date NOT NULL,
"event" text COLLATE pg_catalog."default" NOT NULL
)

TABLESPACE pg_default;

ALTER TABLE public.credit_events_task
OWNER to postgres;

-- Создание таблицы scale_EXP_task. Команда создает пустую таблицу с необходимыми столбцами и их форматами. В созданную таблицу необходимо дальнейшее импортирование данных из csv файла scale_EXP_task. В качестве первичного ключа выбран столбец grade_id, поскольку он не имеет повторяющихся и пустых значений.

-- Аналогично таблицам выше создадим таблицу scale_exp и добавим первичный ключ – поле grade_id не повторяется:

DROP TABLE IF EXISTS public.scale_exp;

CREATE TABLE public.scale_exp
(
"grade" text COLLATE pg_catalog."default" NOT NULL,
"grade_id" smallint NOT NULL,
CONSTRAINT scale_exp_pkey PRIMARY KEY ("grade_id")
)
)
WITH (
OIDS = FALSE
TABLESPACE pg_default;

ALTER TABLE public.scale_exp
OWNER to postgres;

-- Комментарий:
-- Данны не импортированы.

-- Пункт 2.
-- Создадим новую таблицу ratings2, занесем данные из таблицы ratings (аналогично таблицам выше). Зададим первичный ключ.
CREATE TABLE public.ratings2
(
"no_" bigint NOT NULL,
"rat_industry" text COLLATE pg_catalog."default",
"rat_type" text COLLATE pg_catalog."default" NOT NULL,
"horizon" text COLLATE pg_catalog."default",
"scale_typer" text COLLATE pg_catalog."default",
"currency" text COLLATE pg_catalog."default",
"backed_flag" text COLLATE pg_catalog."default",
CONSTRAINT ratings2_pkey PRIMARY KEY ("no_")
)
WITH (
OIDS = FALSE
)
TABLESPACE pg_default;

ALTER TABLE public.ratings2
OWNER to postgres;

-- Пункт 3. Заполним и свяжем таблицы с помощью внешних ключей.
-- Занесем данные из таблицы ratings в ratings2 с помощью команды insert:
INSERT INTO ratings2 SELECT count(*) over (order by "agency_id", "rat_industry", "rat_type", "horizon", "scale_typer", "currency", "backed_flag") as NO,
"agency_id", "rat_industry", "rat_type", "horizon", "scale_typer", "currency", "backed_flag"
FROM (select distinct "agency_id", "rat_industry", "rat_type", "horizon", "scale_typer", "currency", "backed_flag"
FROM ratings)
as my_selec
ALTER TABLE ratings add column "no_" bigint;

-- Заменим поле no_ в исходной таблице ratings на значения из новой таблицы ratings2. Обновим поле с кодами рейтингов, заменив их на уникальные, зададим внешний ключ ratings2.no_:
UPDATE ratings
SET NO=ratings2.no_
FROM ratings_data
WHERE ratings."agency_id"=ratings2."agency_id";
ALTER TABLE public.ratings
ADD CONSTRAINT fr_key FOREIGN KEY (no_) REFERENCES public.ratings2 (no_);

-- Удалим лишние столбцы из таблицы (уже вынесены в ratings2):
ALTER TABLE public.ratings
DROP COLUMN IF EXISTS "rat_industry",
DROP COLUMN IF EXISTS "rat_type",
DROP COLUMN IF EXISTS "horizon",
DROP COLUMN IF EXISTS "scale_typer",
DROP COLUMN IF EXISTS "currency",
DROP COLUMN IF EXISTS "backed_flag";

-- Создадим новую пустую таблицу ent_data для заполнения информацией о рейтингуемых из таблицы ratings.
CREATE TABLE public.ent_data
(
"ent_id" bigint NOT NULL,
"ent_name" text COLLATE pg_catalog."default" NOT NULL,
"okpo" bigint NOT NULL,
"ogrn" bigint,
"inn" bigint,
"finst" bigint,
CONSTRAINT ent_data_pkey PRIMARY KEY ("ent_id")
)
WITH (
OIDS = FALSE
)
TABLESPACE pg_default;
ALTER TABLE public.ent_data
OWNER to postgres;

-- Скопируем информацию из исходной таблицы rating в новую ent_data
INSERT INTO ent_info SELECT count(*) order (order by "ent_name", "okpo", "ogrn", "inn", "finst") as ent_id,
"ent_name", "okpo", "ogrn", "inn", "finst"
FROM (select distinct "ent_name", "okpo", "ogrn", "inn", "finst"
FROM ratings)
as my_select2;

-- Добавим в таблицу ratings поле с ссылками на новую таблицу ent_data:

ALTER TABLE ratings add column "ent_id" bigint;

-- Команда заполняет поле ent_id в исходной таблице ratings_task с кодами-ссылками на новую таблицу ent_data
UPDATE ratings
SET ent_id=ent_data.ent_id
FROM ent_data
WHERE ratings_task."ent_name"=ent_data."ent_name";

-- Команда присваивает полю ent_id ограничение внешнего ключа
ALTER TABLE public.ratings
ADD CONSTRAINT fr_key_1 FOREIKEY (ent_id) REFERENCES public.ent_data (ent_id);

-- Пункт 4.
SELECT rat_id, grade, ent_name, date

FROM ratings, ratings2

INNER JOIN
(SELECT ratings.rat_id, ratings.grade, ratings.rat_id, ratings.ent_name, max(date)
GROUP BY rat.id, grade
ON ratings.rat_id = ratings2.rat.id
AND ratings.grade = ratings2.grade
WHERE change NOT LIKE “%приостановлен” AND NOT LIKE “%снят”

-- Комментарий:
-- Запрос не работает. Ошибки синтаксиса. Идея не соответствует целям запроса в задании.  

-- Оценка будет в онлайн-таблице.