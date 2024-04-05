## Batch Loader and Batch Review Sub-System

## Functions

#### Loader Batch
1. Seed dev data (sql)
1.  Create
1.  Query (basic)
1.  List  (basic)
1.  Tabs
    a.  Details tab
        -  Link to query all the loader names
        -  Link to any batch reviews
    a.  Review tab with form to create a batch review
    a.  Settings tab to set a default query batch for loader names
1.  Query Help (basic)
1.  Query Examples (basic)

#### Loader Names
1.  Seed dev data (sql)
1.  Load batch of loader names (in shell with sql)
1.  Load second batch of loader names (raw orchids data)
1.  Create (not done at this stage, planned for later)
1.  Query 
    a.  Transferred in the orchids-processing queries and adapted to loader names
    b.  Simple batch-review-related queries - e.g. has-review-comment:
1.  List (basic - needs Orchids style markup)
1.  Tabs
    a.  Details tab
        -  Link to its parent batch
    a.  Review tab to add name review comment (if user is authorised)
    a.  Review Comments tab to show comments from all reviews and all periods
1.  Query Help (basic)
1.  Query Examples
    a.  Transferred in the examples from orchids-processing
1.  Data translations on load
    a.  Unplaced = '1' becomes Expired = true
    b.  Script to set the parent_id, translating from the raw_id, and raw_parent_id

#### Batch Review
1.  Create is from loader batch (see above)
1.  Query (basic)
1.  List 
1.  Tabs
    a.  Details tab
        - Link to its Batch parent
        - Link to any child Review Periods
    a.  Edit tab
        - Update the Review name
        - Delete the Review (needs more validation)
    a.  Periods tab
        - Create a review period
           - name
           - start date

#### Batch Review Period
1.  Create is from Batch Review (see above)
1.  Query review periods (basic)
1.  List
1.  Tabs
    a.  Details tab
        - Link to parent Batch Review
        - Count and link to any Reviewers
        - Count and link to any Loader Names which have a Name Review Comment
    a.  Calendar tab
        - Shows the period on a Calendar display (not finished - only first month)
    a.  Edit tab
        - Name
        - Start date
        - End date
    a.  Reviewer tab
        - List reviewers
        - Add a reviewer
1.  Validation rules for periods copied from previous review work
1.  Created `batch_review_period_vw` (sql)

#### Users
1. Seed dev data (sql)
1. Query users
1. List users
1. Show user details

#### Orgs
1. Seed dev data (sql)
1. Query orgs
1. List orgs
1. Show org details

#### Batch Review Roles
1. Seed dev data (sql)

#### Batch Reviewers
1. Seed dev data (sql)
1. Query batch reviewers
1. List batch reviewers
1. Show batch reviewer details
1. Query by review period
1. Display user name info
1. Link to Period

#### Name Review Comments
1. Add a name review comment as a batch reviewer for a loader name within a review period
1. List name review comments against loader names


## Workflows

### Currently only in shell/sql

1. Create batch
1. Load batch of loader names
1. Create user
1. Create organisation
1. Create batch review role

### Batch Review workflows available in the Editor at 08-Dec-2021

See separate document.



### Loader Functions in the Editor (as for Orchids)
1. Indented, flagged listings
1. Comprehensive search options

### Expected
1. Processing tabs (as for Orchids Loader)
1. Summary tab (as for Orchids Loader)
1. Restrictions on reviewer
    a. should see only relevant data
       - loader names (only for the batches they are reviewing)
    b. can comment on loader names only in batches they are reviewing
    c. can see other comments on loader names in batches they are reviewing
1. Comprehensive navigation links
1. Compiler comments
    a. compiler to add name review comments, which will be marked as compiler comments (adjust data structure)
1. Delete review period

### Not Expected
1. Reviewer cannot edit, or delete a comment.  (Thoughts?)
