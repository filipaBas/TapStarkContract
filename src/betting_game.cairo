#[starknet::interface]
trait IBettingContract<TContractState> {
    fn get_prize_pool(self: @TContractState) -> felt252;
    fn get_user_points(self: @TContractState, user: felt252) -> felt252;
    fn transfer_prize(ref self: TContractState, user: felt252);
    fn place_bet(ref self: TContractState, user: felt252, bet_amount: felt252);
}

#[starknet::contract]
mod BettingContract {
    #[storage]
    struct Storage {
        prize_pool: felt252,
        user_points: LegacyMap<ContractAddress, felt252>, 
    }

    #[constructor]
    fn constructor(ref self: ContractState, initial_amount: felt252) {
        //assert initial_amount > 0;
        self.prize_pool.write(initial_amount);
    }

    #[abi(embed_v0)]
    impl BettingContract of super::IBettingContract<ContractState> {
    
        fn get_prize_pool(self: @ContractState) -> felt252 {
            self.prize_pool.read()
        }

        fn get_user_points(ref self: @ContractState, user: felt252) -> felt252 {
            self.user_points.read(user)
        }

        fn place_bet(ref self: ContractState, user: ContractAddress, bet_amount: felt252) {
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

            self.prize_pool.write(0);
         
        }


        fn claim_winnings(ref self: ContractState) {
            let user = get_caller_address(); 
            let (amount) = self.user_balances.read(user); 

            assert amount > 0;

            emit EtherWithdrawn { user, amount };

            self.user_balances.write(user, 0);
        }
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    struct EtherWithdrawn {
        user: ContractAddress,
        amount: felt252,
    }
}