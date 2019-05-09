include: "_date_comparison.view.lkml"

view: your_view_name {

#---- This is an example view file
  dimension_group: your_date_dimension {
    type: time
    timeframes: [date, raw]
  }


#---- Add in these parameters to your own view file replacing your_date_dimension
  extends: [_date_comparison]

  dimension: event_date{
    sql:  ${your_date_dimension_date};;
    type: date
    hidden: yes
  }
  dimension: event_raw{
    sql:  ${your_date_dimension_raw} ;;
    type: date_time
    hidden: yes
  }

}
