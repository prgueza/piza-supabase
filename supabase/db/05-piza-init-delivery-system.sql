/* TABLES */

-- public.client

CREATE TABLE IF NOT EXISTS public.client (
  id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  name TEXT NOT NULL,
  surname TEXT NOT NULL,
  email TEXT NOT NULL,
  phone TEXT NOT NULL,
  avatar_url TEXT NOT NULL
);

COMMENT ON TABLE public.client IS 'Holds information about our beloved clients';
COMMENT ON COLUMN public.client.id IS 'Client ID';
COMMENT ON COLUMN public.client.name IS 'Client name';
COMMENT ON COLUMN public.client.surname IS 'Client surname';
COMMENT ON COLUMN public.client.email IS 'Client email address';
COMMENT ON COLUMN public.client.phone IS 'Client phone number';
COMMENT ON COLUMN public.client.avatar_url IS 'Client avatar url';

-- public.pizza

CREATE TABLE public.pizza (
  id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE public.pizza IS 'List of pizzas made and delivered by us';
COMMENT ON COLUMN public.pizza.id IS 'Pizza ID';
COMMENT ON COLUMN public.pizza.created_at IS 'Time at which the pizza was made';

-- public.dough

CREATE TABLE public.dough (
  id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT NOT NULL
);

COMMENT ON TABLE public.dough IS 'List of available doughs for our clients to pick from';
COMMENT ON COLUMN public.dough.id IS 'Dough ID';
COMMENT ON COLUMN public.dough.name IS 'Dough name';
COMMENT ON COLUMN public.dough.description IS 'Description of the dough';

-- public.ingredient

CREATE TABLE public.ingredient (
  id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT NOT NULL
);

COMMENT ON TABLE public.ingredient IS 'List of available ingredients for our clients to pick from';
COMMENT ON COLUMN public.ingredient.id IS 'Ingredient ID';
COMMENT ON COLUMN public.ingredient.name IS 'Ingredient name';
COMMENT ON COLUMN public.ingredient.description IS 'Description of the ingredient';

-- public.stock_ingredient

CREATE TABLE public.stock_ingredient (
  id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  ingredient_id INT NOT NULL REFERENCES public.ingredient(id),
  pizza_id INT REFERENCES public.pizza(id)
);

COMMENT ON TABLE public.stock_ingredient IS 'List of ingredients in stock for our cooks to use in ordered pizzas';
COMMENT ON COLUMN public.stock_ingredient.id IS 'Stock ID';
COMMENT ON COLUMN public.stock_ingredient.ingredient_id IS 'Ingredient ID for this stock item';
COMMENT ON COLUMN public.stock_ingredient.pizza_id IS 'Pizza ID where the ingredient was used (if NULL this ingredient has not been used yet)';

-- public.stock_dough

CREATE TABLE public.stock_dough (
  id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  dough_id INT NOT NULL REFERENCES public.dough(id),
  pizza_id INT REFERENCES public.pizza(id)
);

COMMENT ON TABLE public.stock_dough IS 'List of doughs in stock for our cooks to use in ordered pizzas';
COMMENT ON COLUMN public.stock_dough.id IS 'Stock ID';
COMMENT ON COLUMN public.stock_dough.dough_id IS 'Dough ID for this stock item';
COMMENT ON COLUMN public.stock_dough.pizza_id IS 'Pizza ID where the dough was used (if NULL this dough has not been used yet)';

-- public.order

CREATE TYPE public.delivery_status AS ENUM ('delivered', 'not delivered');

COMMENT ON TYPE public.delivery_status IS 'Options for the delivery_status column (delivered / not delivered)';

CREATE TABLE public.order (
  id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  client_id INT NOT NULL REFERENCES public.client(id),
  pizza_id INT REFERENCES public.pizza(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  delivered_at TIMESTAMPTZ,
  delivery_status public.delivery_status
);

COMMENT ON TABLE public.order IS 'List of orders';
COMMENT ON COLUMN public.order.id IS 'Order ID';
COMMENT ON COLUMN public.order.client_id IS 'Client ID that reflects who ordered this pizza';
COMMENT ON COLUMN public.order.pizza_id IS 'Pizza ID that refelcts which pizza was delivered to the client (if no pizza was delivered, or has not been delivered yet, this field is NULL)';
COMMENT ON COLUMN public.order.created_at IS 'Time at which the order was placed';
COMMENT ON COLUMN public.order.delivered_at IS 'Time at which the order was delivered (this field updates automatically when the delivery_status changes)';
COMMENT ON COLUMN public.order.delivery_status IS 'Final status of the order (delivered or not delivered)';

CREATE OR REPLACE FUNCTION public.fn_handle_dispatch()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $function$
  BEGIN
    
    IF NEW.delivery_status = 'delivered'::public.delivery_status THEN

      NEW.delivered_at := NOW();
    
    END IF;

    RETURN NEW;

  END;
$function$;

COMMENT ON FUNCTION public.fn_handle_dispatch IS 'Updates the delivered_at column in the orders table when the status changes';

CREATE OR REPLACE TRIGGER tr_on_dispatch BEFORE UPDATE 
  OF delivery_status
  ON public.order FOR EACH ROW 
  EXECUTE FUNCTION public.fn_handle_dispatch();

COMMENT ON TRIGGER tr_on_dispatch ON public.order IS 'Used for updating the delivered_at column in response to a change in its delivery_status';

-- public.order_dough

CREATE TABLE public.order_dough (
  id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  order_id INT NOT NULL REFERENCES public.order(id),
  dough_id INT NOT NULL REFERENCES public.dough(id)
);

COMMENT ON TABLE public.order_dough IS 'Relation table between the order and the dough ordered';
COMMENT ON COLUMN public.order_dough.order_id IS 'Order ID';
COMMENT ON COLUMN public.order_dough.dough_id IS 'Dough ID';

-- public.order_ingredient

CREATE TABLE public.order_ingredient (
  id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  order_id INT NOT NULL REFERENCES public.order(id),
  ingredient_id INT NOT NULL REFERENCES public.ingredient(id)
);

COMMENT ON TABLE public.order_ingredient IS 'Relation table between the order and the ingredients ordered';
COMMENT ON COLUMN public.order_ingredient.order_id IS 'Stock ID';
COMMENT ON COLUMN public.order_ingredient.ingredient_id IS 'Ingredient ID';

/* DATA */

INSERT INTO public.client ("name", surname, email, phone, avatar_url) VALUES
  ('Proud', 'Owner', 'owner@piza.com', '563-340-3352', 'https://images.unsplash.com/photo-1597223557154-721c1cecc4b0?ixlib=rb-1.2.1&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=240&q=80'),
  ('Scott', 'Bruce', 's.bruce@piza.clients.com', '267-288-6798', 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?ixlib=rb-1.2.1&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=240&q=80'),
  ('Betty', 'Morrison', 'b.morrison@piza.clients.com', '253-266-4348', 'https://images.unsplash.com/photo-1479936343636-73cdc5aae0c3?ixlib=rb-1.2.1&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=240&q=80'),
  ('James', 'Wentworth', 'j.wentworth@piza.clients.com', '616-536-9234', 'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?ixlib=rb-1.2.1&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=240&q=80'),
  ('Bernice', 'Fields', 'b.fields@piza.clients.com', '406-246-9699', 'https://images.unsplash.com/photo-1519699047748-de8e457a634e?ixlib=rb-1.2.1&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=240&q=80'),
  ('Christopher', 'Bucklin', 'c.bucklin@piza.clients.com', '662-756-4685', 'https://images.unsplash.com/photo-1542909168-82c3e7fdca5c?ixlib=rb-1.2.1&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=240&q=80');

INSERT INTO public.dough ("name", "description") VALUES
  ('Thin', 'Paperlike dough. In fact, dough? what dough?'),
  ('Crusty', 'Provides the best chewing sounds you will ever hear'),
  ('Cheesy', 'Not enough cheese? Try this');

INSERT INTO public.ingredient ("name", "description") VALUES
  ('Bacon', 'Good ol bacon for your pizza'),
  ('Beef', 'Some cattle meat for you to enjoy'),
  ('Chicken pops', 'Breaded and fried tasty chicken'),
  ('Pepperoni', 'Sounds like pepper but not even close. Much better in fact'),
  ('Tuna', 'Eww'),
  ('Pineapple', 'Bring some controversy to the table'),
  ('Mushrooms', 'Turn your pizza into a salad'),
  ('Tomato', 'Tomato? Really?'),
  ('Extra cheese', 'Cheese is never enough'),
  ('Onion', ':_(');