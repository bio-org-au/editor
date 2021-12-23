insert into batch_review_period (batch_review_id, name, start_date) select id, 'First period for '||name, current_date + 10 from batch_review;
