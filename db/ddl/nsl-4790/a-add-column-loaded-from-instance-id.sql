alter table loader_name add column loaded_from_instance_id bigint;


-- Note: trialling without FK constraint because we've had trouble in the past
-- locking instances down because they match an orchid record - the trouble
-- arises when users want to delete the instance referred to in the orchid loader.
-- Not clear what the right approach is here - to force acknowldgement of the 
-- involvement with a loader record or allow independent work on instances which 
-- may happen long after the loader referral was important.
