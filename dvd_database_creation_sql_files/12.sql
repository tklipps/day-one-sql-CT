

--
-- TOC entry 3206 (class 0 OID 41500)
-- Dependencies: 230
-- Data for Name: staff; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.staff (staff_id, first_name, last_name, address_id, email, store_id, active, username, password, last_update, picture) VALUES (1, 'Mike', 'Hillyer', 3, 'Mike.Hillyer@sakilastaff.com', 1, true, 'Mike', '8cb2237d0679ca88db6464eac60da96345513964', '2006-05-16 16:13:11.79328', '\x89504e470d0a5a0a');
INSERT INTO public.staff (staff_id, first_name, last_name, address_id, email, store_id, active, username, password, last_update, picture) VALUES (2, 'Jon', 'Stephens', 4, 'Jon.Stephens@sakilastaff.com', 2, true, 'Jon', '8cb2237d0679ca88db6464eac60da96345513964', '2006-05-16 16:13:11.79328', NULL);


--
-- TOC entry 3208 (class 0 OID 41511)
-- Dependencies: 232
-- Data for Name: store; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.store (store_id, manager_staff_id, address_id, last_update) VALUES (1, 1, 1, '2006-02-15 09:57:12');
INSERT INTO public.store (store_id, manager_staff_id, address_id, last_update) VALUES (2, 2, 2, '2006-02-15 09:57:12');


--
-- TOC entry 3214 (class 0 OID 0)
-- Dependencies: 202
-- Name: actor_actor_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.actor_actor_id_seq', 200, true);


--
-- TOC entry 3215 (class 0 OID 0)
-- Dependencies: 211
-- Name: address_address_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.address_address_id_seq', 605, true);


--
-- TOC entry 3216 (class 0 OID 0)
-- Dependencies: 204
-- Name: category_category_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.category_category_id_seq', 16, true);


--
-- TOC entry 3217 (class 0 OID 0)
-- Dependencies: 213
-- Name: city_city_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.city_city_id_seq', 600, true);


--
-- TOC entry 3218 (class 0 OID 0)
-- Dependencies: 215
-- Name: country_country_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.country_country_id_seq', 109, true);


--
-- TOC entry 3219 (class 0 OID 0)
-- Dependencies: 200
-- Name: customer_customer_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.customer_customer_id_seq', 599, true);


--
-- TOC entry 3220 (class 0 OID 0)
-- Dependencies: 206
-- Name: film_film_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.film_film_id_seq', 1000, true);


--
-- TOC entry 3221 (class 0 OID 0)
-- Dependencies: 219
-- Name: inventory_inventory_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.inventory_inventory_id_seq', 4581, true);


--
-- TOC entry 3222 (class 0 OID 0)
-- Dependencies: 221
-- Name: language_language_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.language_language_id_seq', 6, true);


--
-- TOC entry 3223 (class 0 OID 0)
-- Dependencies: 224
-- Name: payment_payment_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.payment_payment_id_seq', 32098, true);


--
-- TOC entry 3224 (class 0 OID 0)
-- Dependencies: 226
-- Name: rental_rental_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.rental_rental_id_seq', 16049, true);


--
-- TOC entry 3225 (class 0 OID 0)
-- Dependencies: 229
-- Name: staff_staff_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.staff_staff_id_seq', 2, true);


--
-- TOC entry 3226 (class 0 OID 0)
-- Dependencies: 231
-- Name: store_store_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.store_store_id_seq', 2, true);


--
-- TOC entry 2970 (class 2606 OID 41527)
-- Name: actor actor_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.actor
    ADD CONSTRAINT actor_pkey PRIMARY KEY (actor_id);


--
-- TOC entry 2985 (class 2606 OID 41529)
-- Name: address address_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.address
    ADD CONSTRAINT address_pkey PRIMARY KEY (address_id);


--
-- TOC entry 2973 (class 2606 OID 41531)
-- Name: category category_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.category
    ADD CONSTRAINT category_pkey PRIMARY KEY (category_id);


--
-- TOC entry 2988 (class 2606 OID 41533)
-- Name: city city_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.city
    ADD CONSTRAINT city_pkey PRIMARY KEY (city_id);


--
-- TOC entry 2991 (class 2606 OID 41535)
-- Name: country country_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.country
    ADD CONSTRAINT country_pkey PRIMARY KEY (country_id);


--
-- TOC entry 2965 (class 2606 OID 41537)
-- Name: customer customer_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customer
    ADD CONSTRAINT customer_pkey PRIMARY KEY (customer_id);


--
-- TOC entry 2980 (class 2606 OID 41539)
-- Name: film_actor film_actor_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.film_actor
    ADD CONSTRAINT film_actor_pkey PRIMARY KEY (actor_id, film_id);


--
-- TOC entry 2983 (class 2606 OID 41541)
-- Name: film_category film_category_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.film_category
    ADD CONSTRAINT film_category_pkey PRIMARY KEY (film_id, category_id);


--
-- TOC entry 2976 (class 2606 OID 41543)
-- Name: film film_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.film
    ADD CONSTRAINT film_pkey PRIMARY KEY (film_id);


--
-- TOC entry 2994 (class 2606 OID 41545)
-- Name: inventory inventory_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory
    ADD CONSTRAINT inventory_pkey PRIMARY KEY (inventory_id);


--
-- TOC entry 2996 (class 2606 OID 41547)
-- Name: language language_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.language
    ADD CONSTRAINT language_pkey PRIMARY KEY (language_id);


--
-- TOC entry 3001 (class 2606 OID 41549)
-- Name: payment payment_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payment
    ADD CONSTRAINT payment_pkey PRIMARY KEY (payment_id);


--
-- TOC entry 3005 (class 2606 OID 41551)
-- Name: rental rental_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rental
    ADD CONSTRAINT rental_pkey PRIMARY KEY (rental_id);


--
-- TOC entry 3007 (class 2606 OID 41553)
-- Name: staff staff_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.staff
    ADD CONSTRAINT staff_pkey PRIMARY KEY (staff_id);


--
-- TOC entry 3010 (class 2606 OID 41555)
-- Name: store store_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.store
    ADD CONSTRAINT store_pkey PRIMARY KEY (store_id);


--
-- TOC entry 2974 (class 1259 OID 41556)
-- Name: film_fulltext_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX film_fulltext_idx ON public.film USING gist (fulltext);


--
-- TOC entry 2971 (class 1259 OID 41557)
-- Name: idx_actor_last_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_actor_last_name ON public.actor USING btree (last_name);


--
-- TOC entry 2966 (class 1259 OID 41558)
-- Name: idx_fk_address_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_fk_address_id ON public.customer USING btree (address_id);


--
-- TOC entry 2986 (class 1259 OID 41559)
-- Name: idx_fk_city_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_fk_city_id ON public.address USING btree (city_id);


--
-- TOC entry 2989 (class 1259 OID 41560)
-- Name: idx_fk_country_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_fk_country_id ON public.city USING btree (country_id);


--
-- TOC entry 2997 (class 1259 OID 41561)
-- Name: idx_fk_customer_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_fk_customer_id ON public.payment USING btree (customer_id);


--
-- TOC entry 2981 (class 1259 OID 41562)
-- Name: idx_fk_film_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_fk_film_id ON public.film_actor USING btree (film_id);


--
-- TOC entry 3002 (class 1259 OID 41563)
-- Name: idx_fk_inventory_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_fk_inventory_id ON public.rental USING btree (inventory_id);


--
-- TOC entry 2977 (class 1259 OID 41564)
-- Name: idx_fk_language_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_fk_language_id ON public.film USING btree (language_id);


--
-- TOC entry 2998 (class 1259 OID 41565)
-- Name: idx_fk_rental_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_fk_rental_id ON public.payment USING btree (rental_id);


--
-- TOC entry 2999 (class 1259 OID 41566)
-- Name: idx_fk_staff_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_fk_staff_id ON public.payment USING btree (staff_id);


--
-- TOC entry 2967 (class 1259 OID 41567)
-- Name: idx_fk_store_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_fk_store_id ON public.customer USING btree (store_id);


--
-- TOC entry 2968 (class 1259 OID 41568)
-- Name: idx_last_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_last_name ON public.customer USING btree (last_name);


--
-- TOC entry 2992 (class 1259 OID 41569)
-- Name: idx_store_id_film_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_store_id_film_id ON public.inventory USING btree (store_id, film_id);


--
-- TOC entry 2978 (class 1259 OID 41570)
-- Name: idx_title; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_title ON public.film USING btree (title);


--
-- TOC entry 3008 (class 1259 OID 41571)
-- Name: idx_unq_manager_staff_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_unq_manager_staff_id ON public.store USING btree (manager_staff_id);


--
-- TOC entry 3003 (class 1259 OID 41572)
-- Name: idx_unq_rental_rental_date_inventory_id_customer_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_unq_rental_rental_date_inventory_id_customer_id ON public.rental USING btree (rental_date, inventory_id, customer_id);


--
-- TOC entry 3032 (class 2620 OID 41573)
-- Name: film film_fulltext_trigger; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER film_fulltext_trigger BEFORE INSERT OR UPDATE ON public.film FOR EACH ROW EXECUTE FUNCTION tsvector_update_trigger('fulltext', 'pg_catalog.english', 'title', 'description');


--
-- TOC entry 3030 (class 2620 OID 41574)
-- Name: actor last_updated; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER last_updated BEFORE UPDATE ON public.actor FOR EACH ROW EXECUTE FUNCTION public.last_updated();


--
-- TOC entry 3036 (class 2620 OID 41575)
-- Name: address last_updated; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER last_updated BEFORE UPDATE ON public.address FOR EACH ROW EXECUTE FUNCTION public.last_updated();


--
-- TOC entry 3031 (class 2620 OID 41576)
-- Name: category last_updated; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER last_updated BEFORE UPDATE ON public.category FOR EACH ROW EXECUTE FUNCTION public.last_updated();


--
-- TOC entry 3037 (class 2620 OID 41577)
-- Name: city last_updated; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER last_updated BEFORE UPDATE ON public.city FOR EACH ROW EXECUTE FUNCTION public.last_updated();


--database
-- TOC entry 3029 (class 2620 OID 41579)
-- Name: customer last_updated; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER last_updated BEFORE UPDATE ON public.customer FOR EACH ROW EXECUTE FUNCTION public.last_updated();


--
-- TOC entry 3033 (class 2620 OID 41580)
-- Name: film last_updated; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER last_updated BEFORE UPDATE ON public.film FOR EACH ROW EXECUTE FUNCTION public.last_updated();


--
-- TOC entry 3034 (class 2620 OID 41581)
-- Name: film_actor last_updated; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER last_updated BEFORE UPDATE ON public.film_actor FOR EACH ROW EXECUTE FUNCTION public.last_updated();


--
-- TOC entry 3035 (class 2620 OID 41582)
-- Name: film_category last_updated; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER last_updated BEFORE UPDATE ON public.film_category FOR EACH ROW EXECUTE FUNCTION public.last_updated();


--
-- TOC entry 3039 (class 2620 OID 41583)
-- Name: inventory last_updated; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER last_updated BEFORE UPDATE ON public.inventory FOR EACH ROW EXECUTE FUNCTION public.last_updated();


--
-- TOC entry 3040 (class 2620 OID 41584)
-- Name: language last_updated; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER last_updated BEFORE UPDATE ON public.language FOR EACH ROW EXECUTE FUNCTION public.last_updated();


--
-- TOC entry 3041 (class 2620 OID 41585)
-- Name: rental last_updated; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER last_updated BEFORE UPDATE ON public.rental FOR EACH ROW EXECUTE FUNCTION public.last_updated();


--
-- TOC entry 3042 (class 2620 OID 41586)
-- Name: staff last_updated; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER last_updated BEFORE UPDATE ON public.staff FOR EACH ROW EXECUTE FUNCTION public.last_updated();


--
-- TOC entry 3043 (class 2620 OID 41587)
-- Name: store last_updated; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER last_updated BEFORE UPDATE ON public.store FOR EACH ROW EXECUTE FUNCTION public.last_updated();


--
-- TOC entry 3011 (class 2606 OID 41588)
-- Name: customer customer_address_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customer
    ADD CONSTRAINT customer_address_id_fkey FOREIGN KEY (address_id) REFERENCES public.address(address_id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3013 (class 2606 OID 41593)
-- Name: film_actor film_actor_actor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.film_actor
    ADD CONSTRAINT film_actor_actor_id_fkey FOREIGN KEY (actor_id) REFERENCES public.actor(actor_id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3014 (class 2606 OID 41598)
-- Name: film_actor film_actor_film_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.film_actor
    ADD CONSTRAINT film_actor_film_id_fkey FOREIGN KEY (film_id) REFERENCES public.film(film_id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3015 (class 2606 OID 41603)
-- Name: film_category film_category_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.film_category
    ADD CONSTRAINT film_category_category_id_fkey FOREIGN KEY (category_id) REFERENCES public.category(category_id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3016 (class 2606 OID 41608)
-- Name: film_category film_category_film_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.film_category
    ADD CONSTRAINT film_category_film_id_fkey FOREIGN KEY (film_id) REFERENCES public.film(film_id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3012 (class 2606 OID 41613)
-- Name: film film_language_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.film
    ADD CONSTRAINT film_language_id_fkey FOREIGN KEY (language_id) REFERENCES public.language(language_id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3017 (class 2606 OID 41618)
-- Name: address fk_address_city; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.address
    ADD CONSTRAINT fk_address_city FOREIGN KEY (city_id) REFERENCES public.city(city_id);


--
-- TOC entry 3018 (class 2606 OID 41623)
-- Name: city fk_city; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.city
    ADD CONSTRAINT fk_city FOREIGN KEY (country_id) REFERENCES public.country(country_id);


--
-- TOC entry 3019 (class 2606 OID 41628)
-- Name: inventory inventory_film_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory
    ADD CONSTRAINT inventory_film_id_fkey FOREIGN KEY (film_id) REFERENCES public.film(film_id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3020 (class 2606 OID 41633)
-- Name: payment payment_customer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payment
    ADD CONSTRAINT payment_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES public.customer(customer_id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3021 (class 2606 OID 41638)
-- Name: payment payment_rental_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payment
    ADD CONSTRAINT payment_rental_id_fkey FOREIGN KEY (rental_id) REFERENCES public.rental(rental_id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 3022 (class 2606 OID 41643)
-- Name: payment payment_staff_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payment
    ADD CONSTRAINT payment_staff_id_fkey FOREIGN KEY (staff_id) REFERENCES public.staff(staff_id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3023 (class 2606 OID 41648)
-- Name: rental rental_customer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rental
    ADD CONSTRAINT rental_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES public.customer(customer_id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3024 (class 2606 OID 41653)
-- Name: rental rental_inventory_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rental
    ADD CONSTRAINT rental_inventory_id_fkey FOREIGN KEY (inventory_id) REFERENCES public.inventory(inventory_id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3025 (class 2606 OID 41658)
-- Name: rental rental_staff_id_key; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rental
    ADD CONSTRAINT rental_staff_id_key FOREIGN KEY (staff_id) REFERENCES public.staff(staff_id);


--
-- TOC entry 3026 (class 2606 OID 41663)
-- Name: staff staff_address_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.staff
    ADD CONSTRAINT staff_address_id_fkey FOREIGN KEY (address_id) REFERENCES public.address(address_id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3027 (class 2606 OID 41668)
-- Name: store store_address_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.store
    ADD CONSTRAINT store_address_id_fkey FOREIGN KEY (address_id) REFERENCES public.address(address_id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3028 (class 2606 OID 41673)
-- Name: store store_manager_staff_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.store
    ADD CONSTRAINT store_manager_staff_id_fkey FOREIGN KEY (manager_staff_id) REFERENCES public.staff(staff_id) ON UPDATE CASCADE ON DELETE RESTRICT;


-- Completed on 2021-07-16 14:09:21 EDT

--
-- PostgreSQL database dump complete
