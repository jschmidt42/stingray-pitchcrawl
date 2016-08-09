--
-- Copyright (C) 2015 - All Rights Reserved
-- All rights reserved. http://bathroombreakgames.com
--

ItemDatabase = {
	MinPotionIndex = 0,
	HPPotion = 1,
	MPPotion = 2,
	FocusPoition = 3,
	MaxPotionCount = 50,
	PowerRing = 100,
	MagicRing = 101,
	RegenRing = 102
}

ActionDatabase = {
	Move = { name = "move" },
	PhysicalAttack = { name = "attack" },
	Fireball = {  name = "fireball" },
	Heal = { name = "heal" },
	Charge = { name = "charge" }
}

SkillDatabase = {

}

PitchcrawlDatabase = {
	hero = {
		--
		-- Knight
		--
		old_knight = {
			name = "Old Knight",
			stats = {
				hp = 15,
				mp = 0,
				strength = 5,
				intelligence = 1,
				speed = 4,
				fatigue = 4,
				threat = 0
			},
			actions = {
				ActionDatabase.Move,
				ActionDatabase.PhysicalAttack,
				ActionDatabase.Charge
			},
			equipement = {
				item1 = nil,
				item2 = nil
			}
		},
		--
		-- Mage
		--
		mage = {
			name = "Mage",
			stats = {
				hp = 5,
				mp = 10,
				strength = 3,
				intelligence = 10,
				speed = 4,
				fatigue = 7,
				threat = 0
			},
			actions = {
				ActionDatabase.Move,
				ActionDatabase.PhysicalAttack,
				ActionDatabase.Fireball
			},
			equipement = {
				item1 = nil,
				item2 = nil
			}
		},
		--
		-- Druid
		--
		druid = {
			name = "Druid",
			stats = {
				hp = 8,
				mp = 8,
				strength = 4,
				intelligence = 7,
				speed = 5,
				fatigue = 5,
				threat = 0
			},
			actions = {
				ActionDatabase.Move,
				ActionDatabase.PhysicalAttack,
				ActionDatabase.Heal
			},
			equipement = {
				item1 = nil,
				item2 = nil
			}
		}
	},
	monster = {
		--
		-- Zombie
		--
		zombie = {
			name = "Zomby",
			level = 1,
			stats = {
				hp = 5,
				mp = 0,
				strength = 3,
				intelligence = 1,
				speed = 5,
				fatigue = 7,
				threat = 0
			},
			actions = {
				ActionDatabase.Move,
				ActionDatabase.PhysicalAttack
			},
			drops = {
				[1] = {
					prob = 90,
					drop = nil
				},
				[2] = {
					prob = 100,
					drop = nil
				}
			}
		},
		--
		-- Bat
		--
		bat = {
			name = "Bat",
			level = 1,
			stats = {
				hp = 5,
				mp = 0,
				strength = 3,
				intelligence = 1,
				speed = 5,
				fatigue = 7,
				threat = 0
			},
			actions = {
				ActionDatabase.Move,
				ActionDatabase.PhysicalAttack
			},
			drops = {
				[1] = {
					prob = 90,
					drop = nil
				},
				[2] = {
					prob = 100,
					drop = nil
				}
			}
		},
		--
		-- Demon
		--
		demon = {
			name = "Franky",
			level = 1,
			stats = {
				hp = 15,
				mp = 0,
				strength = 5,
				intelligence = 1,
				speed = 5,
				fatigue = 7,
				threat = 0
			},
			actions = {
				ActionDatabase.Move,
				ActionDatabase.PhysicalAttack
			},
			drops = {
				[1] = {
					prob = 90,
					drop = nil
				},
				[2] = {
					prob = 100,
					drop = nil
				}
			}
		}
	}
}

return PitchcrawlDatabase
