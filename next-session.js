/* The next session, as announced in the site header.
   Hand-edited — this is the one file to touch after each game.

   when       the next session's start, ALWAYS in Arizona time.
              Arizona keeps no daylight saving, so the offset is always -07:00.
              Format: 'YYYY-MM-DDTHH:MM:00-07:00'  (24-hour clock; 18:00 = 6 PM)
              Set to null to say plainly that nothing is on the books.
   mode       'in-person' or 'online'.
   where      optional — a table, a room, a voice channel. Shown only if set.
   runsHours  optional — how long a session runs. Until that much time has passed
              the header says the session is under way; after it, the date has
              gone stale and the header reports no session scheduled. Default 5.

   The page converts `when` into each reader's own local time, wherever they are. */

window.NEXT_SESSION = {
  when: null,               /* e.g. '2026-09-05T18:00:00-07:00' */
  mode: 'in-person',
  where: '',
  runsHours: 5
};
