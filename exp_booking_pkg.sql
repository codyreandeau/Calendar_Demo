create or replace package exp_booking_pkg as

  procedure book_tour(p_tour_date date);
  
  function register_user(p_email varchar2) return number;

end exp_booking_pkg;
/

create or replace package body exp_booking_pkg as

  /**
   * @created_by Cody Reandeau
   * @created February 25, 2025
   *
   * Registers a user if they do not exist
   * @return the user_id of the registered or existing user
   */
  function register_user(p_email varchar2) return number is
    l_user_id exp_users.user_id%type;
  begin
    begin
      select user_id
        into l_user_id
        from exp_users
       where lower(email) = lower(p_email);
    exception
      when no_data_found then
        insert into exp_users (email) values (p_email)
          returning user_id into l_user_id;
    end;
    return l_user_id;
  end register_user;


  /**
   * @created_by Cody Reandeau
   * @created February 25, 2025
   *
   * Books a user for a tour date
   * @param p_tour_date the date of the tour being booked
   */
  procedure book_tour(p_tour_date date) is
    l_user_id exp_users.user_id%type;
    l_capacity exp_dates.capacity%type;
    l_seats_booked exp_dates.seats_booked%type;
    l_tour_date_id exp_dates.tour_date_id%type;
  begin
    -- Get or register user
    l_user_id := register_user(sys_context('APEX$SESSION', 'APP_USER'));

    -- Get the tour date id
    select tour_date_id
         , capacity
         , seats_booked
      into l_tour_date_id
         , l_capacity
         , l_seats_booked
      from exp_dates
     where tour_date = p_tour_date;

    -- ensure there is availability
    if l_seats_booked >= l_capacity then
      raise_application_error(-20001, 'This tour date is fully booked.');
    end if;

    -- insert the booking
    insert into exp_bookings (user_id, tour_date_id,  booking_date)
         values (l_user_id, l_tour_date_id, systimestamp);

    -- update the number of seats booked
    update exp_dates
       set seats_booked = seats_booked + 1
     where tour_date_id = l_tour_date_id;
  exception
    when others then
      raise_application_error(-20001, 'Something went wrong!');
  end book_tour;
end exp_booking_pkg;
/