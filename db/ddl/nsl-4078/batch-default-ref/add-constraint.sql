ALTER TABLE loader_batch ADD CONSTRAINT ref_fk FOREIGN KEY (default_reference_id) REFERENCES reference (id);
