--
-- Copyright (C) 2015 - All Rights Reserved
-- All rights reserved. http://bathroombreakgames.com
--

function math.clamp(val,min,max)
	if min > max then min, max = max, min end
	return math.max(min, math.min(max, val))
end
