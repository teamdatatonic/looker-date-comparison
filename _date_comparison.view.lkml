# this is the code for the date comparison tool, which mimics what google 360 does in the browser in comparing two different date ranges. use with _date_dim.view.lkml
view: _date_comparison {
  extension: required
  filter: current_date_range {
    view_label: "Timeline Comparison Fields"
    label: "1. Date Range"
    description: "Select the date range you are interested in using this filter, can be used by itself. Make sure any filter on Event Date covers this period, or is removed."
    type: date
  }
  filter: previous_date_range {
    view_label: "Timeline Comparison Fields"
    label: "2b. Compare To (Custom):"
    group_label: "Compare to:"

    description: "Use this if you want to specify a custom date range to compare to (limited to 2 comparison periods). Always use with '1. Date Range' filter (or it will error). Make sure any filter on Event Date covers this period, or is removed."

    type: date
  }

  dimension: days_in_period {
    description: "Gives the number of days in the current period date range"
    type: number
    sql: DATE_DIFF(DATE({% date_end current_date_range %}), DATE({% date_start current_date_range %}), DAY) ;;
    hidden:  yes
  }

  dimension: period_2_start {
    description: "Calculates the start of the previous period"
    type: date
    sql:
    {% if compare_to._in_query %}
      {% if compare_to._parameter_value == "Period" %}
        DATE_SUB(DATE({% date_start current_date_range %}), INTERVAL ${days_in_period} DAY)
      {% else %}
        DATE_SUB(DATE({% date_start current_date_range %}), INTERVAL 1 {% parameter compare_to %})
      {% endif %}
    {% else %}
      {% date_start previous_date_range %}
    {% endif %};;
    hidden:  yes
  }

  dimension: period_2_end {
    description: "Calculates the end of the previous period"
    type: date
    sql:
    {% if compare_to._in_query %}
      {% if compare_to._parameter_value == "Period" %}
        DATE_SUB(DATE({% date_start current_date_range %}), INTERVAL 1 DAY)
      {% else %}
        DATE_SUB(DATE_SUB(DATE({% date_end current_date_range %}), INTERVAL 1 DAY), INTERVAL 1 {% parameter compare_to %})
      {% endif %}
    {% else %}
      {% date_end previous_date_range %}
    {% endif %};;
    hidden:  yes
  }

  dimension: period_3_start {
    description: "Calculates the start of 2 periods ago"
    type: date
    sql:
    {% if compare_to._parameter_value == "Period" %}
      DATE_SUB(DATE({% date_start current_date_range %}), INTERVAL 2*${days_in_period} DAY)
    {% else %}
      DATE_SUB(DATE({% date_start current_date_range %}), INTERVAL 2 {% parameter compare_to %})
    {% endif %};;
    hidden: yes

  }

  dimension: period_3_end {
    description: "Calculates the end of 2 periods ago"
    type: date
    sql:
    {% if compare_to._parameter_value == "Period" %}
      DATE_SUB(${period_2_start}, INTERVAL 1 DAY)
    {% else %}
      DATE_SUB(DATE_SUB(DATE({% date_end current_date_range %}), INTERVAL 1 DAY), INTERVAL 2 {% parameter compare_to %})
    {% endif %};;
    hidden: yes
  }

  dimension: period_4_start {
    description: "Calculates the start of 4 periods ago"
    type: date
    sql:
    {% if compare_to._parameter_value == "Period" %}
      DATE_SUB(DATE({% date_start current_date_range %}), INTERVAL 3*${days_in_period} DAY)
    {% else %}
      DATE_SUB(DATE({% date_start current_date_range %}), INTERVAL 3 {% parameter compare_to %})
    {% endif %};;
    hidden: yes
  }

  dimension: period_4_end {
    description: "Calculates the end of 4 periods ago"
    type: date
    sql:
      {% if compare_to._parameter_value == "Period" %}
        DATE_SUB(${period_2_start}, INTERVAL 1 DAY)
      {% else %}
        DATE_SUB(DATE_SUB(DATE({% date_end current_date_range %}), INTERVAL 1 DAY), INTERVAL 3 {% parameter compare_to %})
      {% endif %};;
    hidden: yes
  }

  parameter: compare_to {
    description: "Choose the period you would like to compare to. Must be used with Current Date Range filter"
    label: "2a. Compare To (Templated):"
    type: unquoted
    allowed_value: {
      label: "Previous Period"
      value: "Period"
    }
    allowed_value: {
      label: "Previous Week"
      value: "Week"
    }
    allowed_value: {
      label: "Previous Month"
      value: "Month"
    }
    allowed_value: {
      label: "Previous Quarter"
      value: "Quarter"
    }
    allowed_value: {
      label: "Previous Year"
      value: "Year"
    }
    default_value: "Period"
    view_label: "Timeline Comparison Fields"
  }

  parameter: comparison_periods {
    label: "3. Number of Periods"
    description: "Choose the number of periods you would like to compare - defaults to 2. Only works with templated periods from step 2."
    type: unquoted
    allowed_value: {
      label: "2"
      value: "2"
    }
    allowed_value: {
      label: "3"
      value: "3"
    }
    allowed_value: {
      label: "4"
      value: "4"
    }
    default_value: "2"
    view_label: "Timeline Comparison Fields"
  }

  dimension: period {
    view_label: "Timeline Comparison Fields"
    label: "Period"
    description: "Pivot me! Returns the period the metric covers, i.e. either the 'This Period', 'Previous Period' or '3 Periods Ago'"
    type: string
    order_by_field: order_for_period
    sql:
       {% if current_date_range._is_filtered %}
         CASE
           WHEN {% condition current_date_range %} TIMESTAMP(${event_raw}) {% endcondition %}
           THEN "This {% parameter compare_to %}"
           WHEN ${event_date} between ${period_2_start} and ${period_2_end}
           THEN "Last {% parameter compare_to %}"
           WHEN ${event_date} between ${period_3_start} and ${period_3_end}
           THEN "2 {% parameter compare_to %}s Ago"
           WHEN ${event_date} between ${period_4_start} and ${period_4_end}
           THEN "3 {% parameter compare_to %}s Ago"
         END
       {% else %}
         NULL
       {% endif %}
       ;;
  }

  dimension: order_for_period {
    hidden: yes
    view_label: "Timeline Comparison Fields"
    label: "Period"
    description: "Pivot me! Returns the period the metric covers, i.e. either the 'This Period', 'Previous Period' or '3 Periods Ago'"
    type: string
    sql:
       {% if current_date_range._is_filtered %}
         CASE
           WHEN {% condition current_date_range %} TIMESTAMP(${event_raw}) {% endcondition %}
           THEN 1
           WHEN ${event_date} between ${period_2_start} and ${period_2_end}
           THEN 2
           WHEN ${event_date} between ${period_3_start} and ${period_3_end}
           THEN 3
           WHEN ${event_date} between ${period_4_start} and ${period_4_end}
           THEN 4
         END
       {% else %}
         NULL
       {% endif %}
       ;;
  }

  dimension_group: date_in_period {
    description: "Use this as your date dimension when comparing periods. Aligns the all previous periods onto the current period"
    label: "Current Period"
    type: time
    sql: TIMESTAMP(DATE_ADD(DATE({% date_start current_date_range %}),INTERVAL ${day_in_period}-1 DAY)) ;;
    view_label: "Timeline Comparison Fields"
    timeframes: [date, week, month, quarter, year]
  }

  dimension: day_in_period {
    description: "Gives the number of days since the start of each periods. Use this to align the event dates onto the same axis, the axes will read 1,2,3, etc."
    type: number
    sql:
    {% if current_date_range._is_filtered %}
      CASE
        WHEN {% condition current_date_range %} TIMESTAMP(${event_raw}) {% endcondition %}
        THEN DATE_DIFF(${event_date},date({% date_start current_date_range %}),DAY)+1

        WHEN ${event_date} between ${period_2_start} and ${period_2_end}
        THEN DATE_DIFF(${event_date}, ${period_2_start},DAY)+1

        WHEN ${event_date} between ${period_3_start} and ${period_3_end}
        THEN DATE_DIFF(${event_date}, ${period_3_start},DAY)+1

        WHEN ${event_date} between ${period_4_start} and ${period_4_end}
        THEN DATE_DIFF(${event_date}, ${period_4_start},DAY)+1
      END

    {% else %} NULL
    {% endif %}
    ;;
    hidden: yes
  }

}
