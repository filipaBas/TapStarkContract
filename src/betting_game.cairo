#[starknet::interface]
trait IBettingContract<TContractState> {
    fn get_prize_pool(self: @TContractState) -> felt;
    fn get_user_points(self: @TContractState, user: felt) -> felt;
    fn transfer_prize(ref self: TContractState, user: felt);
    fn place_bet(ref self: TContractState, user: felt, bet_amount: felt);
}

#[starknet::contract]
mod BettingContract {
    #[storage]
    struct Storage {
        prize_pool: felt,
        user_points: LegacyMap<ContractAddress, felt>, 
    }

    #[constructor]
    fn constructor(ref self: ContractState, initial_amount: felt) {
        //assert initial_amount > 0;
        self.prize_pool.write(initial_amount);
    }

    // Implementation of the IBettingContract interface
    #[abi(embed_v0)]
    impl BettingContract of super::IBettingContract<ContractState> {
    
        fn get_prize_pool(self: @ContractState) -> felt {
            self.prize_pool.read()
        }

        fn get_user_points(ref self: @ContractState, user: felt) -> felt {
            self.user_points.read(user)
        }

        fn place_bet(ref self: ContractState, user: ContractAddress, bet_amount: felt) {
            assert bet_amount > 0;

            let (current_pool) = self.prize_pool.read();

            self.prize_pool.write(current_pool + bet_amount);

            let (current_points) = self.user_points.read(user);
            self.user_points.write(user, current_points + 50);
        }

        // Function to transfer the prize to a user when they win
        fn transfer_prize(ref self: ContractState, user: ContractAddress) {
            let (pool) = self.prize_pool.read();
            assert pool > 0;

            self.user_balances.write(user, pool); // Store the user's winnings

            // Reset the prize pool after the transfer
            self.prize_pool.write(0);
         
        }

           // Function for users to claim their Ether winnings
        fn claim_winnings(ref self: ContractState) {
            let user = get_caller_address(); 
            let (amount) = self.user_balances.read(user); 

            assert amount > 0;

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

