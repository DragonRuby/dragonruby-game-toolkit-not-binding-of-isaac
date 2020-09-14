module Upgrade
  TRUE_NEUTRAL = {
      name:        "Neutral Upgrade",
      flavor_text: "What makes a bot turn neutral? Lust for gold? Power? Or was it just manufactured with a CPU full of neutrality?",
      description: "Does nothing. This is a placeholder upgrade and should not show up in game.",
      modifiers:   {
          mult: {
              damage:     1.0,
              speed:      1.0,
              range:      1.0,
              shot_speed: 1.0,
              shot_delay: 1.0,
          },
          flat: {
              damage:     0.0,
              speed:      0.0,
              range:      0.0,
              shot_speed: 0.0,
              shot_delay: 0.0,
          }
      }
  }

  RANGE_FLAT = TRUE_NEUTRAL.deep_merge(
      {
          name:        "Range Booster",
          flavor_text: "Shoot just a little bit further",
          description: "+10 range",
          modifiers:   {
              flat: {
                  range: 1.0
              }
          }
      }
  )

  RANGE_MULT = TRUE_NEUTRAL.deep_merge(
      {
          name:        "Range Doubler",
          flavor_text: "Shoot twice as far!",
          description: "x2 range",
          modifiers:   {
              mult: {
                  range: 2.0
              }
          }
      }
  )

  RANGE_FLAT = TRUE_NEUTRAL.deep_merge(
      {
          name:        "Range Booster",
          flavor_text: "Shoot just a little bit further",
          description: "+10 range",
          modifiers:   {
              flat: {
                  range: 1.0
              }
          }
      }
  )

  RANGE_MULT = TRUE_NEUTRAL.deep_merge(
      {
          name:        "Range Doubler",
          flavor_text: "Shoot twice as far!",
          description: "x2 range",
          modifiers:   {
              mult: {
                  range: 2.0
              }
          }
      }
  )

  DELAY_FLAT = TRUE_NEUTRAL.deep_merge(
      {
          name:        "Fire Rate Booster",
          flavor_text: "Shoot just a little bit faster",
          description: "-1 shot delay",
          modifiers:   {
              flat: {
                  shot_delay: -1
              }
          }
      }
  )

  DELAY_MULT = TRUE_NEUTRAL.deep_merge(
      {
          name:        "Fire Rate Doubler",
          flavor_text: "Shoot twice as fast!",
          description: "x0.5 shot delay",
          modifiers:   {
              mult: {
                  shot_delay: 0.5
              }
          }
      }
  )
end