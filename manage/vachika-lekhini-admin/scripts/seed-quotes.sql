INSERT INTO "FeatureFlag" (key, "valueType", value, description, "updatedAt")
VALUES
  (
    'config.daily_quote_telugu',
    'string',
    '"ధర్మో రక్షతి రక్షితః"',
    'Quote shown on Home screen (Telugu). Leave empty to hide the card.',
    NOW()
  ),
  (
    'config.daily_quote_attribution',
    'string',
    '"మహాభారతం"',
    'Attribution line below the daily quote (e.g. "Ramayana"). Leave empty to hide.',
    NOW()
  )
ON CONFLICT (key) DO UPDATE
  SET value = EXCLUDED.value,
      description = EXCLUDED.description,
      "updatedAt" = NOW();
