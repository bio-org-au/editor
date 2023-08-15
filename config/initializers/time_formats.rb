Time::DATE_FORMATS[:month_day_comma_year] = "%B %e, %Y" # January 28, 2015
Time::DATE_FORMATS[:ddmmyyyy] = "%e %b %Y" # 28 January 2015
Time::DATE_FORMATS[:month_and_year] = "%B %Y"
Time::DATE_FORMATS[:short_ordinal]  = ->(time) { time.strftime("%B #{time.day.ordinalize}") }
