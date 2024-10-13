#[starknet::interface]
trait IBettingContract<TContractState> {
    fn get_prize_pool(self: @TContractState) -> felt;
    fn get_user_points(self: @TContractState, user: felt) -> felt;
    fn transfer_prize(ref self: TContractState, user: felt);
    fn handle_losing_bet(ref self: TContractState, user: felt);
}

// Define the main contract module
#[starknet::contract]
mod BettingContract {
    #[storage]
    struct Storage {
        prize_pool: felt,
        user_points: felt,
    }

    // Constructor to initialize the contract with a prize pool
    #[constructor]
    fn constructor(ref self: ContractState, initial_amount: felt) {
        //assert initial_amount > 0;
        self.prize_pool.write(initial_amount);
    }

    // Implementation of the IBettingContract interface
    #[abi(embed_v0)]
    impl BettingContract of super::IBettingContract<ContractState> {
        // Function to get the current prize pool
        fn get_prize_pool(self: @ContractState) -> felt {
            self.prize_pool.read()
        }

        // Function to get user points
        fn get_user_points(self: @ContractState, user: felt) -> felt {
            self.user_points.read(user)
        }

        // Function to transfer the prize to a user when they win
        fn transfer_prize(ref self: ContractState, user: felt) {
            let (pool) = self.prize_pool.read();
            assert pool > 0;

            // Here, add the logic for the Ether transfer
            self.user_balances.write(user, pool); // Store the user's winnings

            // Reset the prize pool after the transfer
            self.prize_pool.write(0);

            // Increase user points by 1 for winning
            let (points) = self.user_points.read(user);
            self.user_points.write(user, points + 1);
        }

        // Function to handle a losing bet
        fn handle_losing_bet(ref self: ContractState, user: felt) {
            // Increase user points by 3 for losing
            let (points) = self.user_points.read(user);
            self.user_points.write(user, points + 3);
        }

           // Function for users to claim their Ether winnings
        fn claim_winnings(ref self: ContractState) {
            let user = get_caller_address(); // Get the user's address
            let (amount) = self.user_balances.read(user); // Check the balance

            assert amount > 0, "No winnings to claim.";

            // Emit an event for the Ether claim
            emit EtherWithdrawn { user, amount };

            // Reset the user's balance after the claim
            self.user_balances.write(user, 0);
        }
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    struct EtherWithdrawn {
        user: ContractAddress,
        amount: felt,
    }
}

