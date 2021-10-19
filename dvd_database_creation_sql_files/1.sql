--
-- PostgreSQL database dump
--

-- Dumped from database version 13.2 (Debian 13.2-1.pgdg100+1)
-- Dumped by pg_dump version 13.2 (Debian 13.2-1.pgdg100+1)

-- Started on 2021-07-16 14:09:21 EDT

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 666 (class 1247 OID 41356)
-- Name: mpaa_rating; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.mpaa_rating AS ENUM (
    'G',
    'PG',
    'PG-13',
    'R',
    'NC-17'
);


--
-- TOC entry 669 (class 1247 OID 41368)
-- Name: year; Type: DOMAIN; Schema: public; Owner: -
--

CREATE DOMAIN public.year AS integer
	CONSTRAINT year_check CHECK (((VALUE >= 1901) AND (VALUE <= 2155)));


--
-- TOC entry 235 (class 1255 OID 41370)
-- Name: _group_concat(text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public._group_concat(text, text) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $_$
SELECT CASE
  WHEN $2 IS NULL THEN $1
  WHEN $1 IS NULL THEN $2
  ELSE $1 || ', ' || $2
END
$_$;


--
-- TOC entry 236 (class 1255 OID 41371)
-- Name: film_in_stock(integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.film_in_stock(p_film_id integer, p_store_id integer, OUT p_film_count integer) RETURNS SETOF integer
    LANGUAGE sql
    AS $_$
     SELECT inventory_id
     FROM inventory
     WHERE film_id = $1
     AND store_id = $2
     AND inventory_in_stock(inventory_id);
$_$;


--
-- TOC entry 237 (class 1255 OID 41372)
-- Name: film_not_in_stock(integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.film_not_in_stock(p_film_id integer, p_store_id integer, OUT p_film_count integer) RETURNS SETOF integer
    LANGUAGE sql
    AS $_$
    SELECT inventory_id
    FROM inventory
    WHERE film_id = $1
    AND store_id = $2
    AND NOT inventory_in_stock(inventory_id);
$_$;


--
-- TOC entry 238 (class 1255 OID 41373)
-- Name: get_customer_balance(integer, timestamp without time zone); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_customer_balance(p_customer_id integer, p_effective_date timestamp without time zone) RETURNS numeric
    LANGUAGE plpgsql
    AS $$
       --#OK, WE NEED TO CALCULATE THE CURRENT BALANCE GIVEN A CUSTOMER_ID AND A DATE
       --#THAT WE WANT THE BALANCE TO BE EFFECTIVE FOR. THE BALANCE IS:
       --#   1) RENTAL FEES FOR ALL PREVIOUS RENTALS
       --#   2) ONE DOLLAR FOR EVERY DAY THE PREVIOUS RENTALS ARE OVERDUE
       --#   3) IF A FILM IS MORE THAN RENTAL_DURATION * 2 OVERDUE, CHARGE THE REPLACEMENT_COST
       --#   4) SUBTRACT ALL PAYMENTS MADE BEFORE THE DATE SPECIFIED
DECLARE
    v_rentfees DECIMAL(5,2); --#FEES PAID TO RENT THE VIDEOS INITIALLY
    v_overfees INTEGER;      --#LATE FEES FOR PRIOR RENTALS
    v_payments DECIMAL(5,2); --#SUM OF PAYMENTS MADE PREVIOUSLY
BEGIN
    SELECT COALESCE(SUM(film.rental_rate),0) INTO v_rentfees
    FROM film, inventory, rental
    WHERE film.film_id = inventory.film_id
      AND inventory.inventory_id = rental.inventory_id
      AND rental.rental_date <= p_effective_date
      AND rental.customer_id = p_customer_id;

    SELECT COALESCE(SUM(IF((rental.return_date - rental.rental_date) > (film.rental_duration * '1 day'::interval),
        ((rental.return_date - rental.rental_date) - (film.rental_duration * '1 day'::interval)),0)),0) INTO v_overfees
    FROM rental, inventory, film
    WHERE film.film_id = inventory.film_id
      AND inventory.inventory_id = rental.inventory_id
      AND rental.rental_date <= p_effective_date
      AND rental.customer_id = p_customer_id;

    SELECT COALESCE(SUM(payment.amount),0) INTO v_payments
    FROM payment
    WHERE payment.payment_date <= p_effective_date
    AND payment.customer_id = p_customer_id;

    RETURN v_rentfees + v_overfees - v_payments;
END
$$;


--
-- TOC entry 239 (class 1255 OID 41374)
-- Name: inventory_held_by_customer(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.inventory_held_by_customer(p_inventory_id integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_customer_id INTEGER;
BEGIN

  SELECT customer_id INTO v_customer_id
  FROM rental
  WHERE return_date IS NULL
  AND inventory_id = p_inventory_id;

  RETURN v_customer_id;
END $$;


--
-- TOC entry 240 (class 1255 OID 41375)
-- Name: inventory_in_stock(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.inventory_in_stock(p_inventory_id integer) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_rentals INTEGER;
    v_out     INTEGER;
BEGIN
    -- AN ITEM IS IN-STOCK IF THERE ARE EITHER NO ROWS IN THE rental TABLE
    -- FOR THE ITEM OR ALL ROWS HAVE return_date POPULATED

    SELECT count(*) INTO v_rentals
    FROM rental
    WHERE inventory_id = p_inventory_id;

    IF v_rentals = 0 THEN
      RETURN TRUE;
    END IF;

    SELECT COUNT(rental_id) INTO v_out
    FROM inventory LEFT JOIN rental USING(inventory_id)
    WHERE inventory.inventory_id = p_inventory_id
    AND rental.return_date IS NULL;

    IF v_out > 0 THEN
      RETURN FALSE;
    ELSE
      RETURN TRUE;
    END IF;
END $$;


--
-- TOC entry 241 (class 1255 OID 41376)
-- Name: last_day(timestamp without time zone); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.last_day(timestamp without time zone) RETURNS date
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$
  SELECT CASE
    WHEN EXTRACT(MONTH FROM $1) = 12 THEN
      (((EXTRACT(YEAR FROM $1) + 1) operator(pg_catalog.||) '-01-01')::date - INTERVAL '1 day')::date
    ELSE
      ((EXTRACT(YEAR FROM $1) operator(pg_catalog.||) '-' operator(pg_catalog.||) (EXTRACT(MONTH FROM $1) + 1) operator(pg_catalog.||) '-01')::date - INTERVAL '1 day')::date
    END
$_$;


--
-- TOC entry 242 (class 1255 OID 41377)
-- Name: last_updated(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.last_updated() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.last_update = CURRENT_TIMESTAMP;
    RETURN NEW;
END $$;


--
-- TOC entry 200 (class 1259 OID 41378)
-- Name: customer_customer_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.customer_customer_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


-- SET default_table_access_method = heap;

--
-- TOC entry 201 (class 1259 OID 41380)
-- Name: customer; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.customer (
    customer_id integer DEFAULT nextval('public.customer_customer_id_seq'::regclass) NOT NULL,
    store_id smallint NOT NULL,
    first_name character varying(45) NOT NULL,
    last_name character varying(45) NOT NULL,
    email character varying(50),
    address_id smallint NOT NULL,
    activebool boolean DEFAULT true NOT NULL,
    create_date date DEFAULT ('now'::text)::date NOT NULL,
    last_update timestamp without time zone DEFAULT now(),
    active integer
);


--
-- TOC entry 254 (class 1255 OID 41387)
-- Name: rewards_report(integer, numeric); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.rewards_report(min_monthly_purchases integer, min_dollar_amount_purchased numeric) RETURNS SETOF public.customer
    LANGUAGE plpgsql SECURITY DEFINER
    AS $_$
DECLARE
    last_month_start DATE;
    last_month_end DATE;
rr RECORD;
tmpSQL TEXT;
BEGIN

    /* Some sanity checks... */
    IF min_monthly_purchases = 0 THEN
        RAISE EXCEPTION 'Minimum monthly purchases parameter must be > 0';
    END IF;
    IF min_dollar_amount_purchased = 0.00 THEN
        RAISE EXCEPTION 'Minimum monthly dollar amount purchased parameter must be > $0.00';
    END IF;

    last_month_start := CURRENT_DATE - '3 month'::interval;
    last_month_start := to_date((extract(YEAR FROM last_month_start) || '-' || extract(MONTH FROM last_month_start) || '-01'),'YYYY-MM-DD');
    last_month_end := LAST_DAY(last_month_start);

    /*
    Create a temporary storage area for Customer IDs.
    */
    CREATE TEMPORARY TABLE tmpCustomer (customer_id INTEGER NOT NULL PRIMARY KEY);

    /*
    Find all customers meeting the monthly purchase requirements
    */

    tmpSQL := 'INSERT INTO tmpCustomer (customer_id)
        SELECT p.customer_id
        FROM payment AS p
        WHERE DATE(p.payment_date) BETWEEN '||quote_literal(last_month_start) ||' AND '|| quote_literal(last_month_end) || '
        GROUP BY customer_id
        HAVING SUM(p.amount) > '|| min_dollar_amount_purchased || '
        AND COUNT(customer_id) > ' ||min_monthly_purchases ;

    EXECUTE tmpSQL;

    /*
    Output ALL customer information of matching rewardees.
    Customize output as needed.
    */
    FOR rr IN EXECUTE 'SELECT c.* FROM tmpCustomer AS t INNER JOIN customer AS c ON t.customer_id = c.customer_id' LOOP
        RETURN NEXT rr;
    END LOOP;

    /* Clean up */
    tmpSQL := 'DROP TABLE tmpCustomer';
    EXECUTE tmpSQL;

RETURN;
END
$_$;


--
-- TOC entry 755 (class 1255 OID 41388)
-- Name: group_concat(text); Type: AGGREGATE; Schema: public; Owner: -
--

CREATE AGGREGATE public.group_concat(text) (
    SFUNC = public._group_concat,
    STYPE = text
);


--
-- TOC entry 202 (class 1259 OID 41389)
-- Name: actor_actor_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.actor_actor_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 203 (class 1259 OID 41391)
-- Name: actor; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.actor (
    actor_id integer DEFAULT nextval('public.actor_actor_id_seq'::regclass) NOT NULL,
    first_name character varying(45) NOT NULL,
    last_name character varying(45) NOT NULL,
    last_update timestamp without time zone DEFAULT now() NOT NULL
);


--
-- TOC entry 204 (class 1259 OID 41396)
-- Name: category_category_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.category_category_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 205 (class 1259 OID 41398)
-- Name: category; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.category (
    category_id integer DEFAULT nextval('public.category_category_id_seq'::regclass) NOT NULL,
    name character varying(25) NOT NULL,
    last_update timestamp without time zone DEFAULT now() NOT NULL
);


--
-- TOC entry 206 (class 1259 OID 41403)
-- Name: film_film_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.film_film_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 207 (class 1259 OID 41405)
-- Name: film; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.film (
    film_id integer DEFAULT nextval('public.film_film_id_seq'::regclass) NOT NULL,
    title character varying(255) NOT NULL,
    description text,
    release_year public.year,
    language_id smallint NOT NULL,
    rental_duration smallint DEFAULT 3 NOT NULL,
    rental_rate numeric(4,2) DEFAULT 4.99 NOT NULL,
    length smallint,
    replacement_cost numeric(5,2) DEFAULT 19.99 NOT NULL,
    rating public.mpaa_rating DEFAULT 'G'::public.mpaa_rating,
    last_update timestamp without time zone DEFAULT now() NOT NULL,
    special_features text[],
    fulltext tsvector NOT NULL
);


--
-- TOC entry 208 (class 1259 OID 41417)
-- Name: film_actor; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.film_actor (
    actor_id smallint NOT NULL,
    film_id smallint NOT NULL,
    last_update timestamp without time zone DEFAULT now() NOT NULL
);


--
-- TOC entry 209 (class 1259 OID 41421)
-- Name: film_category; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.film_category (
    film_id smallint NOT NULL,
    category_id smallint NOT NULL,
    last_update timestamp without time zone DEFAULT now() NOT NULL
);


--
-- TOC entry 210 (class 1259 OID 41425)
-- Name: actor_info; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.actor_info AS
 SELECT a.actor_id,
    a.first_name,
    a.last_name,
    public.group_concat(DISTINCT (((c.name)::text || ': '::text) || ( SELECT public.group_concat((f.title)::text) AS group_concat
           FROM ((public.film f
             JOIN public.film_category fc_1 ON ((f.film_id = fc_1.film_id)))
             JOIN public.film_actor fa_1 ON ((f.film_id = fa_1.film_id)))
          WHERE ((fc_1.category_id = c.category_id) AND (fa_1.actor_id = a.actor_id))
          GROUP BY fa_1.actor_id))) AS film_info
   FROM (((public.actor a
     LEFT JOIN public.film_actor fa ON ((a.actor_id = fa.actor_id)))
     LEFT JOIN public.film_category fc ON ((fa.film_id = fc.film_id)))
     LEFT JOIN public.category c ON ((fc.category_id = c.category_id)))
  GROUP BY a.actor_id, a.first_name, a.last_name;


--
-- TOC entry 211 (class 1259 OID 41430)
-- Name: address_address_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.address_address_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 212 (class 1259 OID 41432)
-- Name: address; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.address (
    address_id integer DEFAULT nextval('public.address_address_id_seq'::regclass) NOT NULL,
    address character varying(50) NOT NULL,
    address2 character varying(50),
    district character varying(20) NOT NULL,
    city_id smallint NOT NULL,
    postal_code character varying(10),
    phone character varying(20) NOT NULL,
    last_update timestamp without time zone DEFAULT now() NOT NULL
);


--
-- TOC entry 213 (class 1259 OID 41437)
-- Name: city_city_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.city_city_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 214 (class 1259 OID 41439)
-- Name: city; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.city (
    city_id integer DEFAULT nextval('public.city_city_id_seq'::regclass) NOT NULL,
    city character varying(50) NOT NULL,
    country_id smallint NOT NULL,
    last_update timestamp without time zone DEFAULT now() NOT NULL
);


--
-- TOC entry 215 (class 1259 OID 41444)
-- Name: country_country_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.country_country_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 216 (class 1259 OID 41446)
-- Name: country; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.country (
    country_id integer DEFAULT nextval('public.country_country_id_seq'::regclass) NOT NULL,
    country character varying(50) NOT NULL,
    last_update timestamp without time zone DEFAULT now() NOT NULL
);


--
-- TOC entry 217 (class 1259 OID 41451)
-- Name: customer_list; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.customer_list AS
 SELECT cu.customer_id AS id,
    (((cu.first_name)::text || ' '::text) || (cu.last_name)::text) AS name,
    a.address,
    a.postal_code AS "zip code",
    a.phone,
    city.city,
    country.country,
        CASE
            WHEN cu.activebool THEN 'active'::text
            ELSE ''::text
        END AS notes,
    cu.store_id AS sid
   FROM (((public.customer cu
     JOIN public.address a ON ((cu.address_id = a.address_id)))
     JOIN public.city ON ((a.city_id = city.city_id)))
     JOIN public.country ON ((city.country_id = country.country_id)));


--
-- TOC entry 218 (class 1259 OID 41456)
-- Name: film_list; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.film_list AS
 SELECT film.film_id AS fid,
    film.title,
    film.description,
    category.name AS category,
    film.rental_rate AS price,
    film.length,
    film.rating,
    public.group_concat((((actor.first_name)::text || ' '::text) || (actor.last_name)::text)) AS actors
   FROM ((((public.category
     LEFT JOIN public.film_category ON ((category.category_id = film_category.category_id)))
     LEFT JOIN public.film ON ((film_category.film_id = film.film_id)))
     JOIN public.film_actor ON ((film.film_id = film_actor.film_id)))
     JOIN public.actor ON ((film_actor.actor_id = actor.actor_id)))
  GROUP BY film.film_id, film.title, film.description, category.name, film.rental_rate, film.length, film.rating;


--
-- TOC entry 219 (class 1259 OID 41461)
-- Name: inventory_inventory_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.inventory_inventory_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 220 (class 1259 OID 41463)
-- Name: inventory; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.inventory (
    inventory_id integer DEFAULT nextval('public.inventory_inventory_id_seq'::regclass) NOT NULL,
    film_id smallint NOT NULL,
    store_id smallint NOT NULL,
    last_update timestamp without time zone DEFAULT now() NOT NULL
);


--
-- TOC entry 221 (class 1259 OID 41468)
-- Name: language_language_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.language_language_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 222 (class 1259 OID 41470)
-- Name: language; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.language (
    language_id integer DEFAULT nextval('public.language_language_id_seq'::regclass) NOT NULL,
    name character(20) NOT NULL,
    last_update timestamp without time zone DEFAULT now() NOT NULL
);


--
-- TOC entry 223 (class 1259 OID 41475)
-- Name: nicer_but_slower_film_list; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.nicer_but_slower_film_list AS
 SELECT film.film_id AS fid,
    film.title,
    film.description,
    category.name AS category,
    film.rental_rate AS price,
    film.length,
    film.rating,
    public.group_concat((((upper("substring"((actor.first_name)::text, 1, 1)) || lower("substring"((actor.first_name)::text, 2))) || upper("substring"((actor.last_name)::text, 1, 1))) || lower("substring"((actor.last_name)::text, 2)))) AS actors
   FROM ((((public.category
     LEFT JOIN public.film_category ON ((category.category_id = film_category.category_id)))
     LEFT JOIN public.film ON ((film_category.film_id = film.film_id)))
     JOIN public.film_actor ON ((film.film_id = film_actor.film_id)))
     JOIN public.actor ON ((film_actor.actor_id = actor.actor_id)))
  GROUP BY film.film_id, film.title, film.description, category.name, film.rental_rate, film.length, film.rating;


--
-- TOC entry 224 (class 1259 OID 41480)
-- Name: payment_payment_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.payment_payment_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 225 (class 1259 OID 41482)
-- Name: payment; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.payment (
    payment_id integer DEFAULT nextval('public.payment_payment_id_seq'::regclass) NOT NULL,
    customer_id smallint NOT NULL,
    staff_id smallint NOT NULL,
    rental_id integer NOT NULL,
    amount numeric(5,2) NOT NULL,
    payment_date timestamp without time zone NOT NULL
);


--
-- TOC entry 226 (class 1259 OID 41486)
-- Name: rental_rental_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.rental_rental_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 227 (class 1259 OID 41488)
-- Name: rental; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.rental (
    rental_id integer DEFAULT nextval('public.rental_rental_id_seq'::regclass) NOT NULL,
    rental_date timestamp without time zone NOT NULL,
    inventory_id integer NOT NULL,
    customer_id smallint NOT NULL,
    return_date timestamp without time zone,
    staff_id smallint NOT NULL,
    last_update timestamp without time zone DEFAULT now() NOT NULL
);


--
-- TOC entry 228 (class 1259 OID 41493)
-- Name: sales_by_film_category; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.sales_by_film_category AS
 SELECT c.name AS category,
    sum(p.amount) AS total_sales
   FROM (((((public.payment p
     JOIN public.rental r ON ((p.rental_id = r.rental_id)))
     JOIN public.inventory i ON ((r.inventory_id = i.inventory_id)))
     JOIN public.film f ON ((i.film_id = f.film_id)))
     JOIN public.film_category fc ON ((f.film_id = fc.film_id)))
     JOIN public.category c ON ((fc.category_id = c.category_id)))
  GROUP BY c.name
  ORDER BY (sum(p.amount)) DESC;


--
-- TOC entry 229 (class 1259 OID 41498)
-- Name: staff_staff_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.staff_staff_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 230 (class 1259 OID 41500)
-- Name: staff; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.staff (
    staff_id integer DEFAULT nextval('public.staff_staff_id_seq'::regclass) NOT NULL,
    first_name character varying(45) NOT NULL,
    last_name character varying(45) NOT NULL,
    address_id smallint NOT NULL,
    email character varying(50),
    store_id smallint NOT NULL,
    active boolean DEFAULT true NOT NULL,
    username character varying(16) NOT NULL,
    password character varying(40),
    last_update timestamp without time zone DEFAULT now() NOT NULL,
    picture bytea
);


--
-- TOC entry 231 (class 1259 OID 41509)
-- Name: store_store_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.store_store_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 232 (class 1259 OID 41511)
-- Name: store; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.store (
    store_id integer DEFAULT nextval('public.store_store_id_seq'::regclass) NOT NULL,
    manager_staff_id smallint NOT NULL,
    address_id smallint NOT NULL,
    last_update timestamp without time zone DEFAULT now() NOT NULL
);


--
-- TOC entry 233 (class 1259 OID 41516)
-- Name: sales_by_store; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.sales_by_store AS
 SELECT (((c.city)::text || ','::text) || (cy.country)::text) AS store,
    (((m.first_name)::text || ' '::text) || (m.last_name)::text) AS manager,
    sum(p.amount) AS total_sales
   FROM (((((((public.payment p
     JOIN public.rental r ON ((p.rental_id = r.rental_id)))
     JOIN public.inventory i ON ((r.inventory_id = i.inventory_id)))
     JOIN public.store s ON ((i.store_id = s.store_id)))
     JOIN public.address a ON ((s.address_id = a.address_id)))
     JOIN public.city c ON ((a.city_id = c.city_id)))
     JOIN public.country cy ON ((c.country_id = cy.country_id)))
     JOIN public.staff m ON ((s.manager_staff_id = m.staff_id)))
  GROUP BY cy.country, c.city, s.store_id, m.first_name, m.last_name
  ORDER BY cy.country, c.city;


--
-- TOC entry 234 (class 1259 OID 41521)
-- Name: staff_list; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.staff_list AS
 SELECT s.staff_id AS id,
    (((s.first_name)::text || ' '::text) || (s.last_name)::text) AS name,
    a.address,
    a.postal_code AS "zip code",
    a.phone,
    city.city,
    country.country,
    s.store_id AS sid
   FROM (((public.staff s
     JOIN public.address a ON ((s.address_id = a.address_id)))
     JOIN public.city ON ((a.city_id = city.city_id)))
     JOIN public.country ON ((city.country_id = country.country_id)));


--
-- TOC entry 3184 (class 0 OID 41391)
-- Dependencies: 203
-- Data for Name: actor; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (1, 'Penelope', 'Guiness', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (2, 'Nick', 'Wahlberg', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (3, 'Ed', 'Chase', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (4, 'Jennifer', 'Davis', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (5, 'Johnny', 'Lollobrigida', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (6, 'Bette', 'Nicholson', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (7, 'Grace', 'Mostel', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (8, 'Matthew', 'Johansson', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (9, 'Joe', 'Swank', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (10, 'Christian', 'Gable', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (11, 'Zero', 'Cage', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (12, 'Karl', 'Berry', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (13, 'Uma', 'Wood', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (14, 'Vivien', 'Bergen', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (15, 'Cuba', 'Olivier', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (16, 'Fred', 'Costner', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (17, 'Helen', 'Voight', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (18, 'Dan', 'Torn', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (19, 'Bob', 'Fawcett', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (20, 'Lucille', 'Tracy', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (21, 'Kirsten', 'Paltrow', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (22, 'Elvis', 'Marx', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (23, 'Sandra', 'Kilmer', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (24, 'Cameron', 'Streep', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (25, 'Kevin', 'Bloom', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (26, 'Rip', 'Crawford', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (27, 'Julia', 'Mcqueen', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (28, 'Woody', 'Hoffman', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (29, 'Alec', 'Wayne', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (30, 'Sandra', 'Peck', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (31, 'Sissy', 'Sobieski', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (32, 'Tim', 'Hackman', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (33, 'Milla', 'Peck', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (34, 'Audrey', 'Olivier', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (35, 'Judy', 'Dean', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (36, 'Burt', 'Dukakis', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (37, 'Val', 'Bolger', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (38, 'Tom', 'Mckellen', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (39, 'Goldie', 'Brody', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (40, 'Johnny', 'Cage', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (41, 'Jodie', 'Degeneres', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (42, 'Tom', 'Miranda', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (43, 'Kirk', 'Jovovich', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (44, 'Nick', 'Stallone', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (45, 'Reese', 'Kilmer', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (46, 'Parker', 'Goldberg', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (47, 'Julia', 'Barrymore', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (48, 'Frances', 'Day-Lewis', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (49, 'Anne', 'Cronyn', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (50, 'Natalie', 'Hopkins', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (51, 'Gary', 'Phoenix', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (52, 'Carmen', 'Hunt', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (53, 'Mena', 'Temple', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (54, 'Penelope', 'Pinkett', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (55, 'Fay', 'Kilmer', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (56, 'Dan', 'Harris', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (57, 'Jude', 'Cruise', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (58, 'Christian', 'Akroyd', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (59, 'Dustin', 'Tautou', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (60, 'Henry', 'Berry', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (61, 'Christian', 'Neeson', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (62, 'Jayne', 'Neeson', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (63, 'Cameron', 'Wray', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (64, 'Ray', 'Johansson', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (65, 'Angela', 'Hudson', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (66, 'Mary', 'Tandy', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (67, 'Jessica', 'Bailey', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (68, 'Rip', 'Winslet', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (69, 'Kenneth', 'Paltrow', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (70, 'Michelle', 'Mcconaughey', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (71, 'Adam', 'Grant', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (72, 'Sean', 'Williams', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (73, 'Gary', 'Penn', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (74, 'Milla', 'Keitel', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (75, 'Burt', 'Posey', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (76, 'Angelina', 'Astaire', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (77, 'Cary', 'Mcconaughey', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (78, 'Groucho', 'Sinatra', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (79, 'Mae', 'Hoffman', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (80, 'Ralph', 'Cruz', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (81, 'Scarlett', 'Damon', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (82, 'Woody', 'Jolie', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (83, 'Ben', 'Willis', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (84, 'James', 'Pitt', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (85, 'Minnie', 'Zellweger', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (143, 'River', 'Dean', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (86, 'Greg', 'Chaplin', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (87, 'Spencer', 'Peck', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (88, 'Kenneth', 'Pesci', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (89, 'Charlize', 'Dench', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (90, 'Sean', 'Guiness', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (91, 'Christopher', 'Berry', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (92, 'Kirsten', 'Akroyd', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (93, 'Ellen', 'Presley', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (94, 'Kenneth', 'Torn', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (95, 'Daryl', 'Wahlberg', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (96, 'Gene', 'Willis', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (97, 'Meg', 'Hawke', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (98, 'Chris', 'Bridges', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (99, 'Jim', 'Mostel', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (100, 'Spencer', 'Depp', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (101, 'Susan', 'Davis', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (102, 'Walter', 'Torn', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (103, 'Matthew', 'Leigh', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (104, 'Penelope', 'Cronyn', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (105, 'Sidney', 'Crowe', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (106, 'Groucho', 'Dunst', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (107, 'Gina', 'Degeneres', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (108, 'Warren', 'Nolte', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (109, 'Sylvester', 'Dern', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (110, 'Susan', 'Davis', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (111, 'Cameron', 'Zellweger', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (112, 'Russell', 'Bacall', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (113, 'Morgan', 'Hopkins', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (114, 'Morgan', 'Mcdormand', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (115, 'Harrison', 'Bale', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (116, 'Dan', 'Streep', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (117, 'Renee', 'Tracy', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (118, 'Cuba', 'Allen', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (119, 'Warren', 'Jackman', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (120, 'Penelope', 'Monroe', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (121, 'Liza', 'Bergman', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (122, 'Salma', 'Nolte', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (123, 'Julianne', 'Dench', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (124, 'Scarlett', 'Bening', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (125, 'Albert', 'Nolte', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (126, 'Frances', 'Tomei', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (127, 'Kevin', 'Garland', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (128, 'Cate', 'Mcqueen', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (129, 'Daryl', 'Crawford', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (130, 'Greta', 'Keitel', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (131, 'Jane', 'Jackman', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (132, 'Adam', 'Hopper', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (133, 'Richard', 'Penn', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (134, 'Gene', 'Hopkins', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (135, 'Rita', 'Reynolds', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (136, 'Ed', 'Mansfield', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (137, 'Morgan', 'Williams', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (138, 'Lucille', 'Dee', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (139, 'Ewan', 'Gooding', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (140, 'Whoopi', 'Hurt', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (141, 'Cate', 'Harris', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (142, 'Jada', 'Ryder', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (144, 'Angela', 'Witherspoon', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (145, 'Kim', 'Allen', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (146, 'Albert', 'Johansson', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (147, 'Fay', 'Winslet', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (148, 'Emily', 'Dee', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (149, 'Russell', 'Temple', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (150, 'Jayne', 'Nolte', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (151, 'Geoffrey', 'Heston', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (152, 'Ben', 'Harris', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (153, 'Minnie', 'Kilmer', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (154, 'Meryl', 'Gibson', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (155, 'Ian', 'Tandy', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (156, 'Fay', 'Wood', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (157, 'Greta', 'Malden', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (158, 'Vivien', 'Basinger', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (159, 'Laura', 'Brody', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (160, 'Chris', 'Depp', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (161, 'Harvey', 'Hope', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (162, 'Oprah', 'Kilmer', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (163, 'Christopher', 'West', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (164, 'Humphrey', 'Willis', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (165, 'Al', 'Garland', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (166, 'Nick', 'Degeneres', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (167, 'Laurence', 'Bullock', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (168, 'Will', 'Wilson', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (169, 'Kenneth', 'Hoffman', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (170, 'Mena', 'Hopper', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (171, 'Olympia', 'Pfeiffer', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (172, 'Groucho', 'Williams', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (173, 'Alan', 'Dreyfuss', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (174, 'Michael', 'Bening', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (175, 'William', 'Hackman', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (176, 'Jon', 'Chase', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (177, 'Gene', 'Mckellen', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (178, 'Lisa', 'Monroe', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (179, 'Ed', 'Guiness', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (180, 'Jeff', 'Silverstone', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (181, 'Matthew', 'Carrey', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (182, 'Debbie', 'Akroyd', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (183, 'Russell', 'Close', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (184, 'Humphrey', 'Garland', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (185, 'Michael', 'Bolger', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (186, 'Julia', 'Zellweger', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (187, 'Renee', 'Ball', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (188, 'Rock', 'Dukakis', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (189, 'Cuba', 'Birch', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (190, 'Audrey', 'Bailey', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (191, 'Gregory', 'Gooding', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (192, 'John', 'Suvari', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (193, 'Burt', 'Temple', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (194, 'Meryl', 'Allen', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (195, 'Jayne', 'Silverstone', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (196, 'Bela', 'Walken', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (197, 'Reese', 'West', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (198, 'Mary', 'Keitel', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (199, 'Julia', 'Fawcett', '2013-05-26 14:47:57.62');
INSERT INTO public.actor (actor_id, first_name, last_name, last_update) VALUES (200, 'Thora', 'Temple', '2013-05-26 14:47:57.62');
