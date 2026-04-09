#
# this is the command I used to test these scripts
#
# dropdb ned_test; createdb -O nsl ned_test; bundle exec rake db:schema:dump; bundle exec rake db:clean_up_structure_sql; RAILS_ENV=test bin/rails db:setup
#
#
#
namespace :db do
  desc "Clean up the structure.sql file - run this after you generate structure.sql"
  task clean_up_structure_sql: :environment do
    sh "ed db/structure.sql <lib/scripts/structure/a.ed"
    sh "ed db/structure.sql <lib/scripts/structure/b.ed"
    sh "ed db/structure.sql <lib/scripts/structure/c.ed"
    sh "ed db/structure.sql <lib/scripts/structure/c1.ed"
    sh "ed db/structure.sql <lib/scripts/structure/c2.ed"
    sh "ed db/structure.sql <lib/scripts/structure/d.ed"
    sh "ed db/structure.sql <lib/scripts/structure/e.ed"
    sh "ed db/structure.sql <lib/scripts/structure/f.ed"
    sh "ed db/structure.sql <lib/scripts/structure/g.ed"
    sh "ed db/structure.sql <lib/scripts/structure/h.ed"
    sh "ed db/structure.sql <lib/scripts/structure/i.ed"
    sh "ed db/structure.sql <lib/scripts/structure/j.ed"
    sh "ed db/structure.sql <lib/scripts/structure/k.ed"
    sh "ed db/structure.sql <lib/scripts/structure/l.ed"
    sh "ed db/structure.sql <lib/scripts/structure/m.ed"
    sh "ed db/structure.sql <lib/scripts/structure/n.ed"
    sh "ed db/structure.sql <lib/scripts/structure/o.ed"
    sh "ed db/structure.sql <lib/scripts/structure/p.ed"
    sh "ed db/structure.sql <lib/scripts/structure/q.ed"
    sh "ed db/structure.sql <lib/scripts/structure/r.ed"
    sh "ed db/structure.sql <lib/scripts/structure/s.ed"
    sh "ed db/structure.sql <lib/scripts/structure/t.ed"
    sh "ed db/structure.sql <lib/scripts/structure/u.ed"
    sh "ed db/structure.sql <lib/scripts/structure/v.ed"
    sh "ed db/structure.sql <lib/scripts/structure/w.ed"
    sh "ed db/structure.sql <lib/scripts/structure/x.ed"
    sh "ed db/structure.sql <lib/scripts/structure/y.ed"
    sh "ed db/structure.sql <lib/scripts/structure/z.ed"
    sh "ed db/structure.sql <lib/scripts/structure/z1.ed"
    sh "ed db/structure.sql <lib/scripts/structure/z2.ed"
    sh "ed db/structure.sql <lib/scripts/structure/z3.ed"
    sh "ed db/structure.sql <lib/scripts/structure/z4.ed"
    sh "ed db/structure.sql <lib/scripts/structure/z5.ed"
    sh "ed db/structure.sql <lib/scripts/structure/z6.ed"
    sh "ed db/structure.sql <lib/scripts/structure/z7.ed"
    sh "ed db/structure.sql <lib/scripts/structure/z8.ed"
    sh "ed db/structure.sql <lib/scripts/structure/z9.ed"
    sh "ed db/structure.sql <lib/scripts/structure/z9a.ed"
    sh "ed db/structure.sql <lib/scripts/structure/z9b.ed"
  end

end



