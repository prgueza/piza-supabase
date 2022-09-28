/* BACKOFFICE SCHEMA */

CREATE SCHEMA IF NOT EXISTS backoffice;

/* TABLES */

-- backoffice.supply_dough

CREATE TABLE backoffice.supply_dough (
  dough_id INT PRIMARY KEY REFERENCES public.dough(id),
  quantity INT NOT NULL DEFAULT 10
);

COMMENT ON TABLE backoffice.supply_dough IS 'Determines the quantity of each dough we ask for to our suppliers';
COMMENT ON COLUMN backoffice.supply_dough.dough_id IS 'Dough ID';
COMMENT ON COLUMN backoffice.supply_dough.quantity IS 'Ammount of that dough to be supplied';

-- backoffice.supply_ingredient

CREATE TABLE backoffice.supply_ingredient (
  ingredient_id INT PRIMARY KEY REFERENCES public.ingredient(id),
  quantity INT NOT NULL DEFAULT 12
);

COMMENT ON TABLE backoffice.supply_ingredient IS 'Determines the quantity of each ingredient we ask for to our suppliers';
COMMENT ON COLUMN backoffice.supply_ingredient.ingredient_id IS 'Ingredient ID';
COMMENT ON COLUMN backoffice.supply_ingredient.quantity IS 'Ammount of that ingredient to be supplied';

-- backoffice.runner

CREATE TABLE backoffice.runner (
  runner TEXT PRIMARY KEY,
  is_active BOOLEAN NOT NULL DEFAULT TRUE
);

COMMENT ON TABLE backoffice.runner IS 'Used to activate/deactivate the runners';
COMMENT ON COLUMN backoffice.runner.runner IS 'Runner ID';
COMMENT ON COLUMN backoffice.runner.is_active IS 'Determines if the runner is active or not';

/* FUNCTIONS */

CREATE OR REPLACE FUNCTION backoffice.random_between (low INT, high INT) 
  RETURNS INT 
  LANGUAGE plpgsql
AS $function$

  BEGIN

    RETURN FLOOR(RANDOM()* (high - low + 1) + low)::INT;

  END;

$function$;

CREATE OR REPLACE FUNCTION backoffice.place_order()
  RETURNS VOID
  LANGUAGE plpgsql
AS $FUNCTION$

  DECLARE

    _client_id INT;
    _dough_id INT;
    _ingredient_ids INT[];
    _order_id INT;

  BEGIN
        
      -- Select a random client
      SELECT id
      INTO _client_id
      FROM public.client
      WHERE id != 1 -- The owner orders through the app
      ORDER BY RANDOM()
      LIMIT 1;
  
      -- Select a random dough
      SELECT id
      INTO _dough_id
      FROM public.dough
      ORDER BY RANDOM()
      LIMIT 1;
  
      -- Select between 2 and 6 random ingredients
      WITH ingredients AS (
        SELECT id
        FROM public.ingredient
        ORDER BY RANDOM()
        LIMIT backoffice.random_between(2, 6)
      ) SELECT ARRAY_AGG(id) INTO _ingredient_ids FROM ingredients;
  
      -- Create the order
      INSERT INTO public.order (client_id) 
      VALUES (_client_id)
      RETURNING id INTO _order_id;
  
      -- Insert the ordered dough
      INSERT INTO public.order_dough (order_id, dough_id) 
      VALUES (_order_id, _dough_id);
  
      -- Insert the ordered ingredients
      INSERT INTO public.order_ingredient (order_id, ingredient_id) 
      SELECT _order_id order_id, UNNEST(_ingredient_ids) ingredient_id;

      RAISE NOTICE 'Client with id % just ordered a pizza! (Dough: %; Ingredients: %)', _client_id, _dough_id, ARRAY_TO_STRING(_ingredient_ids, ',');

  END;

$FUNCTION$;

CREATE OR REPLACE PROCEDURE backoffice.place_order_runner()
  LANGUAGE plpgsql
AS $PROCEDURE$

  DECLARE

    _interval_from INT := 1;
    _interval_to INT := 3;

  BEGIN

    WHILE TRUE LOOP

      IF (SELECT is_active FROM backoffice.runner WHERE runner = 'place_order') THEN

        PERFORM backoffice.place_order();

        COMMIT;

        PERFORM PG_SLEEP(backoffice.random_between(_interval_from, _interval_to));

        COMMIT;

      ELSE
      
        RAISE NOTICE 'The place_order runner is disabled, sorry we are closed :(';

      END IF;


    END LOOP;

  END;

$PROCEDURE$;

CREATE OR REPLACE FUNCTION backoffice.supply ()
  RETURNS VOID
  LANGUAGE plpgsql
AS $FUNCTION$

  DECLARE
    
    dough_id INT;
    ingredient_id INT;
    quantity INT;

  BEGIN

    RAISE NOTICE 'The supplies truck is here with doughs and ingredients!';

    -- Insert missing doughs up to the quantity set in the supply_doughs configuration
    FOR dough_id, quantity IN 
      SELECT supply.dough_id, GREATEST(supply.quantity - COUNT(stock.*), 0) quantity
      FROM backoffice.supply_dough supply
      LEFT JOIN public.stock_dough stock ON supply.dough_id = stock.dough_id AND stock.pizza_id IS NULL
      GROUP BY supply.dough_id, supply.quantity
    LOOP

      INSERT INTO public.stock_dough (dough_id) 
      SELECT dough_id
      FROM GENERATE_SERIES(0, quantity) AS a(n);

      RAISE NOTICE '% doughs with id % supplied!', quantity, dough_id;
    
    END LOOP;

    -- Insert missing ingredients up to the quantity set in the supply_ingredients configuration
    FOR ingredient_id, quantity IN 
      SELECT supply.ingredient_id, GREATEST(supply.quantity - COUNT(stock.*), 0) quantity
      FROM backoffice.supply_ingredient supply
      LEFT JOIN public.stock_ingredient stock ON supply.ingredient_id = stock.ingredient_id AND stock.pizza_id IS NULL
      GROUP BY supply.ingredient_id, supply.quantity
    LOOP

      INSERT INTO public.stock_ingredient (ingredient_id) 
      SELECT ingredient_id
      FROM GENERATE_SERIES(0, quantity) AS a(n);

      RAISE NOTICE '% ingredients with id % supplied!', quantity, ingredient_id;
    
    END LOOP;

  END;

$FUNCTION$;

CREATE OR REPLACE PROCEDURE backoffice.supply_runner()
  LANGUAGE plpgsql
AS $PROCEDURE$

  DECLARE

    _interval INT := 60;

  BEGIN

    WHILE TRUE LOOP

      IF (SELECT is_active FROM backoffice.runner WHERE runner = 'supply') THEN

        PERFORM backoffice.supply();

        COMMIT;

        PERFORM PG_SLEEP(_interval);

        COMMIT;

      ELSE

        RAISE NOTICE 'The supply runner is disabled, we might run out of ingredients :S';
      
      END IF;

    END LOOP;

  END;

$PROCEDURE$;

/* DATA */

INSERT INTO backoffice.runner (runner, is_active) VALUES
  ('supply', TRUE),
  ('place_order', TRUE);

INSERT INTO backoffice.supply_dough (dough_id, quantity) VALUES
  (1, 10),
  (2, 10),
  (3, 10);

INSERT INTO backoffice.supply_ingredient (ingredient_id, quantity) VALUES
  (1, 10),
  (2, 7),
  (3, 9),
  (4, 12),
  (5, 11),
  (6, 8),
  (7, 11),
  (8, 12),
  (9, 10),
  (10, 11);
