-- Seed sample providers matching EmBeLife iOS Provider.samples

insert into public.providers (
  id, name, title, rate_per_hour, rating, review_count, bio, specialties, booking_count, image_name
) values
  (
    'eric',
    'Eric Acmen',
    'Personal Care Aide',
    25,
    4.8,
    5,
    'I believe that every child is unique, and I tailor my care to meet the individual needs and personalities of each child in my care.',
    'Specialties: meal prep, light housekeeping, running errands',
    56,
    'providerAvatar'
  ),
  (
    'maya',
    'Maya Chen',
    'Postpartum Doula',
    40,
    4.9,
    18,
    'I support families through the early postpartum weeks with feeding guidance, recovery care, and calm companionship.',
    'Specialties: lactation support, newborn care, overnight support',
    112,
    'providerAvatar'
  ),
  (
    'jordan',
    'Jordan Lee',
    'Companion Care',
    28,
    4.7,
    9,
    'I focus on meaningful conversation, light activity, and helping clients stay connected to daily routines.',
    'Specialties: companionship, transportation, grocery help',
    41,
    'providerAvatar'
  )
on conflict (id) do update set
  name = excluded.name,
  title = excluded.title,
  rate_per_hour = excluded.rate_per_hour,
  rating = excluded.rating,
  review_count = excluded.review_count,
  bio = excluded.bio,
  specialties = excluded.specialties,
  booking_count = excluded.booking_count,
  image_name = excluded.image_name,
  updated_at = now();
